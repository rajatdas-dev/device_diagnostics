import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../config/diagnostic_config.dart';
import '../models/diagnostic_sample.dart';
import '../reporting/diagnostic_pdf_report.dart';

/// Owns diagnostic sessions. Collection is opt-in and stops when [stop] completes.
class DiagnosticController extends ChangeNotifier {
  DiagnosticController._();
  static final DiagnosticController instance = DiagnosticController._();
  static const MethodChannel _channel =
      MethodChannel('device_diagnostics/native');

  DiagnosticConfig config = DiagnosticConfig();
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
  int _previousRx = 0;
  int _previousTx = 0;
  DateTime? _previousCpuTime;
  int _previousCpuTicks = 0;
  int _frames = 0;
  int _droppedFrames = 0;
  DateTime? _frameWindowStart;
  DateTime? _visitStart;
  String? _visitRoute;

  Future<void> initialize({DiagnosticConfig? config}) async {
    if (initialized) return;
    this.config = config ?? DiagnosticConfig();
    initialized = true;
  }

  void onRouteChanged(String route) {
    if (_visitRoute != null && _visitStart != null && isRecording) {
      screenVisits.add(ScreenVisit(
          route: _visitRoute!,
          enteredAt: _visitStart!,
          exitedAt: DateTime.now(),
          rxBytes: _routeRx[_visitRoute!] ?? 0,
          txBytes: _routeTx[_visitRoute!] ?? 0));
    }
    _visitRoute = route;
    _visitStart = DateTime.now();
    currentRoute = route;
    notifyListeners();
  }

  void recordNetwork({required int receivedBytes, required int sentBytes}) {
    if (!isRecording) return;
    _routeRx[currentRoute] = (_routeRx[currentRoute] ?? 0) + receivedBytes;
    _routeTx[currentRoute] = (_routeTx[currentRoute] ?? 0) + sentBytes;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!isRecording || !config.enableFrameMonitoring) return;
    for (final timing in timings) {
      _frames++;
      if (timing.totalSpan >
          const Duration(milliseconds: 16, microseconds: 667)) {
        _droppedFrames++;
      }
    }
  }

  Future<void> start() async {
    if (!initialized) await initialize(config: config);
    if (isRecording) return;
    samples.clear();
    screenVisits.clear();
    _routeRx.clear();
    _routeTx.clear();
    _previousRx = 0;
    _previousTx = 0;
    _previousCpuTicks = 0;
    _previousCpuTime = null;
    _frames = 0;
    _droppedFrames = 0;
    sessionStartedAt = DateTime.now();
    sessionEndedAt = null;
    _visitStart = DateTime.now();
    _visitRoute = currentRoute;
    isRecording = true;
    if (config.enableFrameMonitoring) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }
    await _sample();
    _timer = Timer.periodic(config.sampleInterval, (_) => _sample());
    notifyListeners();
  }

  Future<void> _sample() async {
    if (!isRecording) return;
    Map<dynamic, dynamic> native = <dynamic, dynamic>{};
    try {
      native =
          await _channel.invokeMapMethod<dynamic, dynamic>('sampleMetrics') ??
              <dynamic, dynamic>{};
    } on PlatformException catch (_) {
      /* Unsupported native metrics remain null. */
    }
    final now = DateTime.now();

    final int? currentCpuTicks =
        native['cpuTicks'] is num ? (native['cpuTicks'] as num).toInt() : null;

    final int? currentCpuTimeMicros = native['cpuTimeMicros'] is num
        ? (native['cpuTimeMicros'] as num).toInt()
        : null;

    double? calculatedCpuPercent;

    if (currentCpuTicks != null && currentCpuTimeMicros != null) {
      if (_previousCpuTime != null && currentCpuTicks >= _previousCpuTicks) {
        final elapsedMicros =
            currentCpuTimeMicros - _previousCpuTime!.microsecondsSinceEpoch;

        final tickDelta = currentCpuTicks - _previousCpuTicks;

        if (elapsedMicros > 0) {
          calculatedCpuPercent =
              (tickDelta / elapsedMicros * 100).clamp(0.0, 100.0);
        }
      }

      _previousCpuTime = DateTime.fromMicrosecondsSinceEpoch(
        currentCpuTimeMicros,
      );
      _previousCpuTicks = currentCpuTicks;
    }

    for (final key in <String>[
      'model',
      'manufacturer',
      'osVersion',
      'soc',
      'architecture',
      'hardwareDecoder'
    ]) {
      final value = native[key];
      if (value != null) deviceMetadata[key] = value;
    }
    final int? memory = native['memoryBytes'] as int?;

    final double? nativeCpuPercent = native['cpuPercent'] is num
        ? (native['cpuPercent'] as num).toDouble()
        : null;

    final double? cpu = nativeCpuPercent ?? calculatedCpuPercent;

    final int? rxTotal = native['rxBytes'] as int?;
    final int? txTotal = native['txBytes'] as int?;
    int? rxDelta;
    int? txDelta;
    if (rxTotal != null && txTotal != null) {
      if (_previousRx != 0 || _previousTx != 0) {
        rxDelta = (rxTotal - _previousRx).clamp(0, 1 << 62).toInt();
        txDelta = (txTotal - _previousTx).clamp(0, 1 << 62).toInt();
      }
      _previousRx = rxTotal;
      _previousTx = txTotal;
    }
    final double elapsed = _frameWindowStart == null
        ? config.sampleInterval.inMilliseconds / 1000
        : now.difference(_frameWindowStart!).inMilliseconds / 1000;
    final double? fps =
        elapsed > 0 && _frameWindowStart != null ? _frames / elapsed : null;
    final int dropped = _droppedFrames;
    _frames = 0;
    _droppedFrames = 0;
    _frameWindowStart = now;
    samples.add(DiagnosticSample(
        timestamp: now,
        memoryBytes: config.enableMemoryMonitoring ? memory : null,
        cpuPercent: config.enableCpuMonitoring ? cpu : null,
        fps: fps,
        droppedFrames: dropped,
        networkType: native['networkType'] as String?,
        rxBytes: rxDelta,
        txBytes: txDelta,
        thermalState: config.enableThermalMonitoring
            ? native['thermalState'] as String?
            : null));
    notifyListeners();
  }

  Future<String> stopAndExportPdf({bool share = true}) async {
    if (!isRecording) throw StateError('No diagnostic session is active.');
    _timer?.cancel();
    _timer = null;
    if (config.enableFrameMonitoring) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    if (_visitRoute != null && _visitStart != null) {
      screenVisits.add(ScreenVisit(
          route: _visitRoute!,
          enteredAt: _visitStart!,
          exitedAt: DateTime.now(),
          rxBytes: _routeRx[_visitRoute!] ?? 0,
          txBytes: _routeTx[_visitRoute!] ?? 0));
    }
    isRecording = false;
    sessionEndedAt = DateTime.now();
    notifyListeners();
    return DiagnosticPdfReport().generate(controller: this, share: share);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
