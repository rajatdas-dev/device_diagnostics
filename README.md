# device_diagnostics

**Session-based diagnostics and performance monitoring for Flutter applications.**

`device_diagnostics` helps Flutter developers inspect application performance, monitor instrumented network requests, track route visits, and export diagnostic reports as PDFs.

Created and maintained by **Rajat Das**.

## Features

- 📊 **Diagnostic sessions** — collect metrics while a session is running.
- 🎛️ **Floating diagnostic overlay** — start and stop collection from an in-app panel.
- ⚡ **Frame performance monitoring** — collect Flutter frame timing information.
- 🌐 **HTTP instrumentation** — record requests made through `DiagnosticHttpClient`.
- 🧭 **Route tracking** — integrate navigation observation into diagnostic sessions.
- 📱 **Native platform metrics** — collect supported device and operating-system information.
- 📄 **PDF reports** — generate local diagnostic reports and optionally open the platform share sheet.
- ⚙️ **Configurable behavior** — configure overlay visibility and sampling behavior.

Metric availability depends on the platform and the underlying native implementation. See [Collected metrics and limitations](#collected-metrics-and-limitations) before relying on individual metrics.

## Installation

Add the dependency to your application's `pubspec.yaml`:

```yaml
dependencies:
  device_diagnostics: ^0.0.1
```

Then run:

```bash
flutter pub get
```

Import the package:

```dart
import 'package:device_diagnostics/device_diagnostics.dart';
```

## Quick start

Initialize the package before starting your application:

```dart
import 'package:device_diagnostics/device_diagnostics.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceDiagnostics.initialize(
    config: DiagnosticConfig(
      visibility: DiagnosticVisibility.debug,
    ),
  );

  runApp(
    DeviceDiagnostics.observability(
      child: MaterialApp(
        navigatorObservers: [
          DeviceDiagnostics.routeObserver,
        ],
        home: const MyHomePage(),
      ),
    ),
  );
}
```

Replace `MyHomePage` with your application's home page.

The visibility setting controls when the diagnostic overlay is visible:

- `DiagnosticVisibility.debug` — show it in debug mode.
- `DiagnosticVisibility.release` — show it in release mode.
- `DiagnosticVisibility.debugAndRelease` — show it in both modes.

These options control overlay visibility, not Flutter's compilation mode. Check your installed package version and public API if the configuration options differ in your implementation.

## Instrument HTTP requests

Use `DiagnosticHttpClient` for the HTTP traffic you want the package to record:

```dart
final client = DiagnosticHttpClient();

try {
  final response = await client.get(
    Uri.parse('https://example.com/api'),
  );

  // Process the response in your application.
} finally {
  client.close();
}
```

**Instrumentation boundary:** requests are only counted when they pass through `DiagnosticHttpClient`. Other HTTP clients, WebViews, native libraries, and unrelated application traffic are not automatically intercepted.

Route attribution is based on the package's current instrumentation behavior and may be approximate when requests overlap or navigation changes.

## Diagnostic sessions and PDF reports

The floating diagnostic panel lets you start and stop collection.

When collection stops, the package generates a PDF report in the application's documents directory under `device_diagnostics/`. Sharing is enabled by default in the documented flow.

To save the report without opening the share sheet, use the controller's supported export method:

```dart
await controller.stopAndExportPdf(share: false);
```

Obtain `controller` from the public controller API available in your installed version. Avoid creating a second controller if the package uses a shared controller instance.

## Collected metrics and limitations

| Metric | Android | iOS |
|---|---|---|
| App/process memory | PSS estimate | Resident memory estimate |
| CPU | `/proc/self/stat`-based estimate | Not implemented |
| Frame timing | Flutter frame timing callbacks | Flutter frame timing callbacks |
| Network type | Active transport | `NWPathMonitor` |
| System network byte counters | UID counters, subject to platform limitations | Unavailable |
| Instrumented HTTP bytes | Requests through `DiagnosticHttpClient` | Requests through `DiagnosticHttpClient` |
| Thermal state | Android 10+ status | iOS 11+ state |
| Device and OS information | Android build properties | Machine identifier and iOS version |
| SoC model | Supported Android versions | Unavailable |
| Hardware decoder status | Unavailable | Unavailable |

These metrics are not equivalent to unrestricted device-wide monitoring.

- Missing metrics should be treated as **unavailable**, not as zero.
- Android traffic counters may be cumulative since boot and may include other components sharing the application's UID.
- System network counters are not route-specific.
- The Android thermal metric is a coarse thermal state, not a direct temperature reading.
- Ordinary iOS applications cannot access general process CPU usage or device-wide network byte totals through this plugin.
- Validate CPU calculations, metric accuracy, and sampling overhead on physical devices before using the results for production decisions.

## Performance considerations

The package is designed to start collection when a diagnostic session begins rather than continuously collecting metrics.

- The documented default sampling interval is one second.
- The minimum documented interval is 250 milliseconds.
- PDF generation occurs after recording stops.

Sampling consumes resources. Measure CPU, memory, battery, and frame performance overhead on representative devices before enabling continuous or production diagnostics.

## Permissions and privacy

On Android, the plugin requests `ACCESS_NETWORK_STATE` to inspect the active network transport. This does not require a runtime permission prompt.

Diagnostic reports may include device information, performance measurements, route activity, and network metadata. Before shipping diagnostics to end users:

- Obtain appropriate user consent.
- Avoid logging credentials, request bodies, sensitive identifiers, or full URLs containing personal information.
- Explain what is collected and why.
- Define report retention, sharing, and deletion behavior.
- Review platform permissions and privacy requirements for your app.

Do not assume that diagnostic reports are safe to share publicly.

## Example application

The repository includes an example application for exploring the package.

From the repository root:

```bash
flutter pub get
flutter analyze
flutter test

cd example
flutter pub get
flutter run
```

Run the example on physical Android and iOS devices to validate native metrics that are unavailable or incomplete in simulators.

## Architecture

The package separates diagnostic collection from the application's feature code:

```text
Flutter Application
       |
       +-- Diagnostic initialization
       |
       +-- Route observer
       |
       +-- DiagnosticHttpClient
       |
       v
Diagnostic Session
       |
       +-- Frame timing
       +-- Supported native metrics
       +-- Instrumented HTTP activity
       +-- Route activity
       |
       v
Diagnostic Report
       |
       +-- Local PDF
       +-- Optional platform sharing
```

Only explicitly integrated components are instrumented. The package does not provide unrestricted inspection of all application or device activity.

## Development

Contributions and bug reports are welcome.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test example
flutter analyze
flutter test
```

Native changes should also be validated with Android and iOS builds where applicable.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines and [SECURITY.md](SECURITY.md) for reporting security issues.

## Roadmap

- Improve Android CPU normalization and validation.
- Improve route attribution for overlapping HTTP requests.
- Add validated real-device integration tests.
- Evaluate additional report visualization and export options.
- Investigate supported approaches to additional platform metrics.

Roadmap items are planned work, not promises that the functionality is already available.

## Author

**Rajat Das**  
Flutter Developer | Mobile Application Developer

- GitHub: [rajatdas-dev](https://github.com/rajatdas-dev)
- Repository: [device_diagnostics](https://github.com/rajatdas-dev/device_diagnostics)
- Issues: [Report a bug or request a feature](https://github.com/rajatdas-dev/device_diagnostics/issues)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
