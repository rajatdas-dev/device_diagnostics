
import 'package:device_diagnostics/device_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticConfig', () {
    test('defaults to debug visibility and a one-second interval', () {
      const config = DiagnosticConfig();

      expect(config.visibility, DiagnosticVisibility.debug);
      expect(config.sampleInterval, const Duration(seconds: 1));
    });

    test('supports debugAndRelease visibility', () {
      const config = DiagnosticConfig(
        visibility: DiagnosticVisibility.debugAndRelease,
      );

      expect(
        config.visibility,
        DiagnosticVisibility.debugAndRelease,
      );
    });

    test('accepts the minimum sample interval', () {
      const config = DiagnosticConfig(
        sampleInterval: Duration(milliseconds: 250),
      );

      expect(() => config.validate(), returnsNormally);
    });

    test('rejects intervals below 250 milliseconds', () {
      const config = DiagnosticConfig(
        sampleInterval: Duration(milliseconds: 100),
      );

      expect(
            () => config.validate(),
        throwsArgumentError,
      );
    });

    test('allows disabling network monitoring', () {
      const config = DiagnosticConfig(
        enableNetworkMonitoring: false,
      );

      expect(config.enableNetworkMonitoring, isFalse);
    });
  });
}
