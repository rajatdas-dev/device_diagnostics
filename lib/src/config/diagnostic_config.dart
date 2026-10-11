
import 'package:flutter/foundation.dart';

enum DiagnosticVisibility {
  /// Show the diagnostic overlay only in Debug builds.
  debug,

  /// Show the diagnostic overlay only in Profile builds.
  profile,

  /// Show the diagnostic overlay only in Release builds.
  release,

  /// Show the diagnostic overlay in Debug and Release builds.
  debugAndRelease,

  /// Show the diagnostic overlay in Debug, Profile, and Release builds.
  all,
}

class DiagnosticConfig {
  const DiagnosticConfig({
    this.visibility = DiagnosticVisibility.debug,
    this.sampleInterval = const Duration(seconds: 1),
    this.enableThermalMonitoring = true,
    this.enableCpuMonitoring = true,
    this.enableMemoryMonitoring = true,
    this.enableNetworkMonitoring = true,
    this.enableFrameMonitoring = true,
    this.showFloatingButtonWhenIdle = true,
  });

  final DiagnosticVisibility visibility;
  final Duration sampleInterval;
  final bool enableThermalMonitoring;
  final bool enableCpuMonitoring;
  final bool enableMemoryMonitoring;
  final bool enableNetworkMonitoring;
  final bool enableFrameMonitoring;
  final bool showFloatingButtonWhenIdle;

  /// Validates settings before collecting diagnostic data.
  ///
  /// A minimum interval prevents excessively frequent native sampling.
  void validate() {
    if (sampleInterval.inMicroseconds <
        const Duration(milliseconds: 250).inMicroseconds) {
      throw ArgumentError.value(
        sampleInterval,
        'sampleInterval',
        'Must be at least 250 milliseconds.',
      );
    }
  }

  bool get isVisibleInCurrentBuild {
    switch (visibility) {
      case DiagnosticVisibility.debug:
        return kDebugMode;
      case DiagnosticVisibility.profile:
        return kProfileMode;
      case DiagnosticVisibility.release:
        return kReleaseMode;
      case DiagnosticVisibility.debugAndRelease:
        return kDebugMode || kReleaseMode;
      case DiagnosticVisibility.all:
        return true;
    }
  }
}
