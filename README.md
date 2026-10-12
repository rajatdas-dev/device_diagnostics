# 🔍 device_diagnostics

### Flutter Device Diagnostics & Performance Monitoring

[![pub package](https://img.shields.io/pub/v/device_diagnostics.svg)](https://pub.dev/packages/device_diagnostics)
[![likes](https://img.shields.io/pub/likes/device_diagnostics)](https://pub.dev/packages/device_diagnostics)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/rajatdas-dev/device_diagnostics)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Built with ❤️ by [Rajat Das](https://github.com/rajatdas-dev) · [Connect on LinkedIn](https://www.linkedin.com/in/rajat-das-658248219)**

A Flutter package for opt-in device diagnostics, performance monitoring, HTTP network instrumentation, route tracking, and PDF diagnostic reports. Designed to help Flutter developers investigate performance issues, understand runtime behavior, and collect useful diagnostic information during debugging and testing.

---

## ✨ Features

- 📱 **Device information** — Model, manufacturer, OS version, and architecture where available.
- ⚡ **CPU monitoring** — Process CPU usage estimates where supported.
- 🧠 **Memory monitoring** — Track application memory usage.
- 🌡️ **Thermal monitoring** — Inspect device thermal state where supported.
- 🌐 **HTTP network instrumentation** — Record request and response body-byte metrics through the provided diagnostic client.
- 🎞️ **Frame monitoring** — Observe Flutter frame performance and estimate dropped frames.
- 🧭 **Route tracking** — Associate diagnostic activity with supported navigation events.
- 📄 **PDF reports** — Export collected diagnostic sessions for inspection and sharing.
- 🎛️ **Flexible visibility modes** — Configure diagnostics for Debug, Profile, Release, Debug + Release, or all build modes.
- 🛡️ **Opt-in diagnostics** — Choose when and how diagnostics are enabled.

> **Note:** Metric availability and accuracy depend on the platform, OS version, and underlying implementation. Some metrics may be estimated or unavailable.

## 📦 Installation

Add `device_diagnostics` to your `pubspec.yaml` using the version currently published on pub.dev:

```yaml
dependencies:
  device_diagnostics: ^0.1.0
```

Then run:

```bash
flutter pub get
```

Check the [latest published version](https://pub.dev/packages/device_diagnostics) before installing.

## 🚀 Quick Start

Initialize the package before calling `runApp()`.

```dart
import 'package:flutter/material.dart';
import 'package:device_diagnostics/device_diagnostics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceDiagnostics.initialize(
    config: const DiagnosticConfig(
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

### How it works

1. `DeviceDiagnostics.initialize()` initializes the diagnostic configuration.
2. `DiagnosticConfig` controls visibility and supported monitoring options.
3. `DeviceDiagnostics.observability()` wraps your app with the diagnostic UI.
4. `DeviceDiagnostics.routeObserver` tracks supported navigation events.

## 🎛️ Visibility Modes

Choose which Flutter build modes can display the diagnostic interface.

| Mode | Debug | Profile | Release |
|---|---|---|---|
| `debug` | ✅ Visible | ❌ Hidden | ❌ Hidden |
| `profile` | ❌ Hidden | ✅ Visible | ❌ Hidden |
| `release` | ❌ Hidden | ❌ Hidden | ✅ Visible |
| `debugAndRelease` | ✅ Visible | ❌ Hidden | ✅ Visible |
| `all` | ✅ Visible | ✅ Visible | ✅ Visible |

### Examples

**Debug only**

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.debug,
)
```

**Profile only**

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.profile,
)
```

**Release only**

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.release,
)
```

**Debug and Release**

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.debugAndRelease,
)
```

**All build modes**

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.all,
)
```

> ⚠️ **Production warning:** Enabling diagnostic UI in Release builds is intentional and should be evaluated carefully. Visibility settings are not a security boundary or a replacement for access control.

## ⚙️ Configuration

Customize diagnostic sampling and monitoring according to your application's needs.

The following example illustrates the available configuration options; verify the option names against the version you have installed.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.debug,
  sampleInterval: Duration(seconds: 1),
  enableThermalMonitoring: true,
  enableCpuMonitoring: true,
  enableMemoryMonitoring: true,
  enableNetworkMonitoring: true,
  enableFrameMonitoring: true,
  showFloatingButtonWhenIdle: true,
)
```

| Option | Description |
|---|---|
| `visibility` | Selects the build modes in which diagnostics are visible. |
| `sampleInterval` | Controls how frequently metrics are sampled. |
| `enableThermalMonitoring` | Enables thermal-state monitoring where supported. |
| `enableCpuMonitoring` | Enables CPU usage sampling where supported. |
| `enableMemoryMonitoring` | Enables memory monitoring. |
| `enableNetworkMonitoring` | Controls network diagnostics supported by the implementation. |
| `enableFrameMonitoring` | Enables Flutter frame-performance monitoring. |
| `showFloatingButtonWhenIdle` | Controls the floating diagnostic button while a session is idle. |

**Sampling interval:** Use an interval that satisfies your configuration validation. If your implementation enforces a 250 ms minimum, configure `Duration(milliseconds: 250)` or longer.

## 🌐 HTTP Network Instrumentation

Use `DiagnosticHttpClient` to record HTTP body-byte metrics for requests passing through the instrumented client.

```dart
import 'package:flutter/foundation.dart';
import 'package:device_diagnostics/device_diagnostics.dart';

Future<void> fetchData() async {
  final client = DiagnosticHttpClient();

  try {
    final response = await client.get(
      Uri.parse('https://example.com/api'),
    );

    debugPrint('Status code: ${response.statusCode}');
  } finally {
    client.close();
  }
}
```

### What can be measured?

- 📤 Outgoing request body bytes.
- 📥 Incoming response body bytes.
- 🧭 Network activity associated with diagnostic routes, subject to the implementation's attribution behavior.

### Important limitations

- These metrics are not necessarily total device network usage.
- HTTP headers, TLS overhead, retransmissions, and traffic from unrelated clients may not be included.
- Requests made through other HTTP clients or networking APIs are not automatically captured by this client.

## 📊 Diagnostic Sessions

Start a session when you want to investigate a performance issue or reproduce a reported bug.

### Start a session

```dart
final controller = DeviceDiagnostics.controller;

await controller.start();
```

### Stop and export a PDF

```dart
await controller.stopAndExportPdf(
  share: false,
);
```

Set `share: true` if you want to invoke the report-sharing flow supported by the package.

### Recommended workflow

1. ▶️ Start a diagnostic session.
2. 📱 Reproduce the issue on the target device.
3. 🧭 Navigate through the affected screens.
4. ⏹️ Stop the session and generate the report.
5. 📄 Review the report and share it when appropriate.

## 📄 PDF Diagnostic Reports

The package can generate PDF reports from collected diagnostic sessions.

Depending on available data and platform support, reports may include:

- Device and operating-system information.
- CPU and memory measurements.
- Frame-performance observations.
- Recorded HTTP body-byte metrics.
- Screen visits and session timing.
- Diagnostic samples and summary statistics.

Review reports before sharing them. They may contain information about application behavior or usage that should not be distributed publicly.

## 🧭 Route Tracking

Register the diagnostic route observer with your `MaterialApp`:

```dart
MaterialApp(
  navigatorObservers: [
    DeviceDiagnostics.routeObserver,
  ],
  home: const MyHomePage(),
);
```

This lets the package observe supported navigation events and associate diagnostic activity with routes.

**Tip:** Named routes can make route attribution easier to interpret. Behavior may vary when using custom navigation solutions.

## 📱 Platform Support

The package currently declares Android and iOS support. Individual metrics have different platform limitations.

| Metric | Android | iOS |
|---|---|---|
| Device information | Supported fields | Supported fields |
| Memory usage | Where available | Where available |
| Process CPU estimate | Where available | Where available |
| Network type | Where available | Where available |
| Network byte counters | Where supported | May be unavailable |
| Thermal state | Supported Android versions | Supported iOS versions |
| Frame monitoring | Flutter-side monitoring | Flutter-side monitoring |
| PDF generation | Subject to package/platform support | Subject to package/platform support |

Metric support is not the same as full platform support. Unsupported values should be treated as unavailable rather than assumed to be zero.

## 🏗️ Architecture Overview

`device_diagnostics` separates diagnostic responsibilities into focused components:

- **Configuration layer** — Visibility modes and monitoring options.
- **Diagnostic controller** — Session state, sampling, and collected data.
- **Native collectors** — Platform-specific metrics exposed through a method channel.
- **Network instrumentation** — HTTP metrics from the provided client.
- **Route observer** — Supported navigation-event tracking.
- **Diagnostic overlay** — On-screen diagnostic controls and information.
- **PDF report generator** — Creates reports from collected session data.

## 🔒 Privacy and Performance

- Enable diagnostics intentionally, especially in Release builds.
- Review diagnostic reports before sharing them.
- Use only the instrumented client when you want its HTTP activity recorded.
- Select a sampling interval appropriate for your workload.
- Test metric accuracy and overhead on physical devices.
- Do not use UI visibility settings as access control for sensitive information.

## 🛠️ Troubleshooting

### The diagnostic overlay is not visible

- Check whether the selected `DiagnosticVisibility` matches the current build mode.
- Initialize diagnostics before calling `runApp()`.
- Ensure the application is wrapped with `DeviceDiagnostics.observability()`.
- Check the `showFloatingButtonWhenIdle` setting if it is supported by your version.

### Some metrics are missing

- Metric support varies by platform and OS version.
- Some native APIs may return unavailable values.
- iOS network byte counters may not be available in the current implementation.
- Test on a physical device if emulator results are incomplete.

### No network activity is recorded

- Send requests through `DiagnosticHttpClient`.
- Confirm that network monitoring is enabled if your configuration exposes that option.
- Remember that traffic from unrelated clients and networking APIs may not be captured.

## 🧑‍💻 Development

Run the project's checks before submitting changes:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter pub publish --dry-run
```

To validate the example application:

```bash
cd example
flutter pub get
flutter analyze
flutter test
flutter build apk
```

## 🗺️ Roadmap

Potential future improvements include:

- 📊 Additional diagnostic visualizations.
- 🧪 Expanded automated tests.
- 📱 Broader platform-specific metric support.
- 📄 More report customization.
- 🔎 More detailed performance insights.

The roadmap is subject to implementation progress and platform limitations.

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome.

1. Fork the [GitHub repository](https://github.com/rajatdas-dev/device_diagnostics).
2. Create a feature branch.
3. Implement and test your changes.
4. Submit a pull request with a clear description.

## 📬 Support

- 🐛 [Report an issue](https://github.com/rajatdas-dev/device_diagnostics/issues)
- 💻 [GitHub repository](https://github.com/rajatdas-dev/device_diagnostics)
- 📦 [Package on pub.dev](https://pub.dev/packages/device_diagnostics)
- 💼 [Connect on LinkedIn](https://www.linkedin.com/in/rajat-das-658248219)

## 📜 License

Distributed under the [MIT License](LICENSE).

---

**Built with ❤️ by [Rajat Das](https://github.com/rajatdas-dev)**

Flutter Developer · Package Creator · Open-Source Contributor