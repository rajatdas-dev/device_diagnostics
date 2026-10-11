
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../config/diagnostic_config.dart';
import '../models/diagnostic_sample.dart';
import '../reporting/diagnostic_pdf_report.dart';

/// Owns diagnostic sessions.
///
/// Collection is opt-in and stops when [stop] completes.
class DiagnosticController extends ChangeNotifier {
  DiagnosticController._();

  static final DiagnosticController instance = DiagnosticController._();

  static const MethodChannel _channel =
  MethodChannel('device_diagnostics/native');

  DiagnosticConfig config = const DiagnosticConfig();

  bool initialized = false;
  bool isRecording = false;

  DateTime? sessionStartedAt;
  DateTime? sessionEndedAt;

  final List<DiagnosticSample> samples = <DiagnosticSample>[];
  final List<ScreenVisit> screenVisits = <ScreenVisit>[];

  final Map<String, int> _routeRx = <String, int>{};
  final Map<String, int> _routeTx = <String, int>{};

  Map<String, dynamic> deviceMetadata = <String, dynamic>{};

  String currentRoute = 'Unknown';

  Timer? _timer;
  Future<void>? _sampleFuture;

  int? _previousRx;
  int? _previousTx;

  int _frames = 0;
  int _droppedFrames = 0;

  DateTime? _frameWindowStart;
  DateTime? _visitStart;
  String? _visitRoute;

  Future<void> initialize({DiagnosticConfig? config}) async {
    if (initialized) return;

    this.config = config ?? const DiagnosticConfig();
    this.config.validate();

    initialized = true;
  }

  void onRouteChanged(String route) {
    if (_visitRoute != null && _visitStart != null && isRecording) {
      screenVisits.add(
        ScreenVisit(
          route: _visitRoute!,
          enteredAt: _visitStart!,
          exitedAt: DateTime.now(),
          rxBytes: _routeRx[_visitRoute!] ?? 0,
          txBytes: _routeTx[_visitRoute!] ?? 0,
        ),
      );
    }

    _visitRoute = route;
    _visitStart = DateTime.now();
    currentRoute = route;

    if (isRecording) {
      notifyListeners();
    }
  }

  /// Records application-level network traffic attributed to the current route.
  ///
  /// These counters are separate from native process/UID network counters.
  void recordNetwork({
    required int receivedBytes,
    required int sentBytes,
  }) {
    if (!isRecording || !config.enableNetworkMonitoring) return;

    if (receivedBytes < 0 || sentBytes < 0) {
      throw ArgumentError(
        'Network byte counts must not be negative.',
      );
    }

    _routeRx[currentRoute] =
        (_routeRx[currentRoute] ?? 0) + receivedBytes;

    _routeTx[currentRoute] =
        (_routeTx[currentRoute] ?? 0) + sentBytes;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!isRecording || !config.enableFrameMonitoring) return;

    for (final timing in timings) {
      _frames++;

      // Approximate 60 Hz frame budget: 16.667 ms.
      if (timing.totalSpan >
          const Duration(milliseconds: 16, microseconds: 667)) {
        _droppedFrames++;
      }
    }
  }

  Future<void> start() async {
    if (!initialized) {
      await initialize(config: config);
    }

    if (isRecording) return;

    config.validate();

    _timer?.cancel();
    _timer = null;

    samples.clear();
    screenVisits.clear();
    _routeRx.clear();
    _routeTx.clear();
    deviceMetadata.clear();

    _previousRx = null;
    _previousTx = null;

    _frames = 0;
    _droppedFrames = 0;
    _frameWindowStart = DateTime.now();

    sessionStartedAt = DateTime.now();
    sessionEndedAt = null;

    _visitStart = DateTime.now();
    _visitRoute = currentRoute;

    isRecording = true;

    if (config.enableFrameMonitoring) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }

    try {
      await _sample();

      // stop() may have been called while the initial native request
      // was in progress. Do not start a timer for a stopped session.
      if (!isRecording) return;

      _timer = Timer.periodic(
        config.sampleInterval,
            (_) => _sample(),
      );

      notifyListeners();
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  /// Prevents concurrent native sampling requests.
  Future<void> _sample() {
    if (!isRecording) return Future<void>.value();

    final inFlight = _sampleFuture;
    if (inFlight != null) return inFlight;

    final future = _collectSample();
    _sampleFuture = future;

    return future.whenComplete(() {
      if (identical(_sampleFuture, future)) {
        _sampleFuture = null;
      }
    });
  }

  Future<void> _collectSample() async {
    if (!isRecording) return;

    Map<dynamic, dynamic> native = <dynamic, dynamic>{};

    try {
      native =
          await _channel.invokeMapMethod<dynamic, dynamic>(
            'sampleMetrics',
          ) ??
              <dynamic, dynamic>{};
    } on MissingPluginException {
      // Native diagnostics are unavailable on this platform.
    } on PlatformException {
      // Unsupported native metrics remain unavailable.
    }

    // A stop may have occurred while awaiting the platform channel.
    if (!isRecording) return;

    final now = DateTime.now();

    for (final key in <String>[
      'model',
      'manufacturer',
      'osVersion',
      'soc',
      'architecture',
      'hardwareDecoder',
    ]) {
      final value = native[key];
      if (value != null) {
        deviceMetadata[key] = value;
      }
    }

    final memory = _asInt(native['memoryBytes']);

    final nativeCpu = native['cpuPercent'];
    final cpu = nativeCpu is num
        ? nativeCpu.toDouble().clamp(0.0, 100.0).toDouble()
        : null;

    int? rxDelta;
    int? txDelta;

    if (config.enableNetworkMonitoring) {
      final rxTotal = _asInt(native['rxBytes']);
      final txTotal = _asInt(native['txBytes']);

      if (rxTotal != null) {
        final previous = _previousRx;

        if (previous != null && rxTotal >= previous) {
          rxDelta = rxTotal - previous;
        }

        // A counter decrease is treated as a reset. Establish a new
        // baseline instead of reporting a negative delta.
        _previousRx = rxTotal;
      }

      if (txTotal != null) {
        final previous = _previousTx;

        if (previous != null && txTotal >= previous) {
          txDelta = txTotal - previous;
        }

        _previousTx = txTotal;
      }
    } else {
      // Do not retain a stale baseline if monitoring is disabled.
      _previousRx = null;
      _previousTx = null;
    }

    final frameWindowStart = _frameWindowStart;
    final elapsed = frameWindowStart == null
        ? 0.0
        : now.difference(frameWindowStart).inMicroseconds /
        Duration.microsecondsPerSecond;

    final double? fps =
    config.enableFrameMonitoring &&
        frameWindowStart != null &&
        elapsed > 0
        ? _frames / elapsed
        : null;

    final droppedFrames =
    config.enableFrameMonitoring ? _droppedFrames : null;

    _frames = 0;
    _droppedFrames = 0;
    _frameWindowStart = now;

    samples.add(
      DiagnosticSample(
        timestamp: now,
        memoryBytes:
        config.enableMemoryMonitoring ? memory : null,
        cpuPercent: config.enableCpuMonitoring ? cpu : null,
        fps: fps,
        droppedFrames: droppedFrames,
        networkType: config.enableNetworkMonitoring
            ? native['networkType'] as String?
            : null,
        rxBytes: config.enableNetworkMonitoring ? rxDelta : null,
        txBytes: config.enableNetworkMonitoring ? txDelta : null,
        thermalState: config.enableThermalMonitoring
            ? native['thermalState'] as String?
            : null,
      ),
    );

    notifyListeners();
  }

  static int? _asInt(dynamic value) {
    return value is num ? value.toInt() : null;
  }

  /// Stops collecting without generating a report.
  Future<void> stop() async {
    if (!isRecording) return;

    // Flip this before awaiting anything to prevent new samples.
    isRecording = false;

    _timer?.cancel();
    _timer = null;

    if (config.enableFrameMonitoring) {
      SchedulerBinding.instance.removeTimingsCallback(
        _onFrameTimings,
      );
    }

    // Wait for any in-flight native call to finish. Its result will
    // not be appended after isRecording becomes false.
    final inFlight = _sampleFuture;
    if (inFlight != null) {
      await inFlight;
    }

    if (_visitRoute != null && _visitStart != null) {
      screenVisits.add(
        ScreenVisit(
          route: _visitRoute!,
          enteredAt: _visitStart!,
          exitedAt: DateTime.now(),
          rxBytes: _routeRx[_visitRoute!] ?? 0,
          txBytes: _routeTx[_visitRoute!] ?? 0,
        ),
      );
    }

    sessionEndedAt = DateTime.now();
    notifyListeners();
  }

  Future<String> stopAndExportPdf({bool share = true}) async {
    if (!isRecording) {
      throw StateError('No diagnostic session is active.');
    }

    await stop();

    return DiagnosticPdfReport().generate(
      controller: this,
      share: share,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    if (config.enableFrameMonitoring) {
      SchedulerBinding.instance.removeTimingsCallback(
        _onFrameTimings,
      );
    }

    super.dispose();
  }
}
