class DiagnosticSample {
  const DiagnosticSample({
    required this.timestamp,
    this.memoryBytes,
    this.cpuPercent,
    this.fps,
    this.droppedFrames,
    this.networkType,
    this.rxBytes,
    this.txBytes,
    this.thermalState,
  });

  final DateTime timestamp;
  final int? memoryBytes;
  final double? cpuPercent;
  final double? fps;
  final int? droppedFrames;
  final String? networkType;
  final int? rxBytes;
  final int? txBytes;
  final String? thermalState;
}

class ScreenVisit {
  const ScreenVisit(
      {required this.route,
      required this.enteredAt,
      required this.exitedAt,
      this.rxBytes = 0,
      this.txBytes = 0});
  final String route;
  final DateTime enteredAt;
  final DateTime exitedAt;
  final int rxBytes;
  final int txBytes;
  Duration get duration => exitedAt.difference(enteredAt);
}

class DiagnosticDeviceInfo {
  const DiagnosticDeviceInfo(
      {this.model,
      this.osVersion,
      this.manufacturer,
      this.soc,
      this.hardwareDecoder,
      this.architecture});
  final String? model;
  final String? osVersion;
  final String? manufacturer;
  final String? soc;
  final String? hardwareDecoder;
  final String? architecture;
}
