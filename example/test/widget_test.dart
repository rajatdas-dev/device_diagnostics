
import 'package:flutter_test/flutter_test.dart';
import 'package:device_diagnostics_example/main.dart' as app;

void main() {
  testWidgets('Example app starts successfully', (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
