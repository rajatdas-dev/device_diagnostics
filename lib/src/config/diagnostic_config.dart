enum DiagnosticVisibility { debug, release, both }

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
  }) : assert(sampleInterval >= const Duration(milliseconds: 250));

  final DiagnosticVisibility visibility;
  final Duration sampleInterval;
  final bool enableThermalMonitoring;
  final bool enableCpuMonitoring;
  final bool enableMemoryMonitoring;
  final bool enableNetworkMonitoring;
  final bool enableFrameMonitoring;
  final bool showFloatingButtonWhenIdle;

  bool get isVisibleInCurrentBuild {
    switch (visibility) {
      case DiagnosticVisibility.debug:
        return const bool.fromEnvironment('dart.vm.product') == false;
      case DiagnosticVisibility.release:
        return const bool.fromEnvironment('dart.vm.product');
      case DiagnosticVisibility.both:
        return true;
    }
  }
}
