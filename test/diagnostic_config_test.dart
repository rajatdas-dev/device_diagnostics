import 'package:device_diagnostics/device_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug is default visibility', () {
    final config = DiagnosticConfig();

    expect(config.visibility, DiagnosticVisibility.debug);
    expect(config.sampleInterval, const Duration(seconds: 1));
  });

  test('config accepts both visibility modes', () {
    final config = DiagnosticConfig(
      visibility: DiagnosticVisibility.both,
    );

    expect(config.visibility, DiagnosticVisibility.both);
  });
}
