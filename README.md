# 🔍 device_diagnostics

**A Flutter package for opt-in device diagnostics, performance monitoring, network instrumentation, and PDF diagnostic reports.** 📊

[![pub package](https://img.shields.io/pub/v/device_diagnostics.svg)](https://pub.dev/packages/device_diagnostics)
[![likes](https://img.shields.io/pub/likes/device_diagnostics)](https://pub.dev/packages/device_diagnostics)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/rajatdas-dev/device_diagnostics)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Monitor your Flutter application's performance, track network activity, inspect device metrics, and generate diagnostic reports — all through a single package. 🚀

---

## ✨ Features

- 📱 **Device information** — model, manufacturer, operating system, and architecture where available.
- ⚡ **CPU monitoring** — process CPU usage estimates where supported.
- 🧠 **Memory monitoring** — track application memory usage.
- 🌡️ **Thermal monitoring** — inspect device thermal state where supported.
- 🌐 **Network instrumentation** — track HTTP request and response body bytes through the provided client.
- 🎬 **Frame monitoring** — observe frame performance and estimate dropped frames.
- 🧭 **Route tracking** — associate diagnostic activity with application screens.
- 📄 **PDF reports** — export diagnostic sessions for inspection and sharing.
- 🎛️ **Flexible visibility configuration** — choose Debug, Profile, Release, Debug + Release, or All modes.
- 🔒 **Opt-in monitoring** — configure diagnostics according to your application's requirements.

> 💡 Metric availability varies by platform. CPU usage, network traffic, thermal state, and device details may be estimates, unavailable, or platform-dependent.

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  device_diagnostics: ^0.0.1
```

Then run:

```bash
flutter pub get
```

> 🚨 If you are installing a newer published version, replace `0.0.1` with the version listed on [pub.dev](https://pub.dev/packages/device_diagnostics).

## 🚀 Quick Start

Initialize diagnostics before calling `runApp()`:

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

### 🧩 What's happening here?

1. ⚙️ `DeviceDiagnostics.initialize()` initializes the package configuration.
2. 🎛️ `DiagnosticConfig` controls which build modes can display diagnostics and which metrics are enabled.
3. 🧭 `routeObserver` tracks navigation events.
4. 🖥️ `DeviceDiagnostics.observability()` wraps your app with the diagnostic UI when enabled for the current build mode.

## 🎛️ Visibility Modes Explained

Choose when the diagnostic interface should be visible.

| Mode | 🐛 Debug | 🔬 Profile | 🚀 Release |
|---|---|---|---|
| `debug` | ✅ Visible | ❌ Hidden | ❌ Hidden |
| `profile` | ❌ Hidden | ✅ Visible | ❌ Hidden |
| `release` | ❌ Hidden | ❌ Hidden | ✅ Visible |
| `debugAndRelease` | ✅ Visible | ❌ Hidden | ✅ Visible |
| `all` | ✅ Visible | ✅ Visible | ✅ Visible |

### 🐛 `DiagnosticVisibility.debug`

Best for everyday development and debugging.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.debug,
)
```

### 🔬 `DiagnosticVisibility.profile`

Use this mode when profiling performance without enabling the diagnostic UI in ordinary Debug or Release builds.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.profile,
)
```

### 🚀 `DiagnosticVisibility.release`

Enables diagnostic visibility in Release builds. Use it only when you intentionally want diagnostics available in production.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.release,
)
```

### 🔄 `DiagnosticVisibility.debugAndRelease`

Enables diagnostic visibility in Debug and Release builds while hiding it in Profile builds.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.debugAndRelease,
)
```

### 🌍 `DiagnosticVisibility.all`

Enables diagnostic visibility in all three build modes.

```dart
const DiagnosticConfig(
  visibility: DiagnosticVisibility.all,
)
```

> ⚠️ **Important:** Visibility configuration controls the diagnostic UI's build-mode visibility. It should not be treated as a security boundary or a substitute for access control, privacy safeguards, or production monitoring policies.

## ⚙️ Configuration Reference

Configure monitoring according to your application's needs.

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
| 🎛️ `visibility` | Selects the build modes in which the diagnostic UI is visible. |
| ⏱️ `sampleInterval` | Controls how frequently diagnostic metrics are sampled. |
| 🌡️ `enableThermalMonitoring` | Enables thermal-state monitoring where supported. |
| ⚡ `enableCpuMonitoring` | Enables process CPU usage sampling where supported. |
| 🧠 `enableMemoryMonitoring` | Enables memory usage sampling. |
| 🌐 `enableNetworkMonitoring` | Controls network diagnostics when supported by the implementation. |
| 🎬 `enableFrameMonitoring` | Enables frame performance monitoring. |
| 🖲️ `showFloatingButtonWhenIdle` | Controls whether the floating diagnostic button is shown while a session is idle. |

> 💡 The configured sampling interval must be at least **250 milliseconds** if your configuration validation enforces that minimum.

## 🌐 HTTP Network Instrumentation

Use `DiagnosticHttpClient` to record HTTP body-byte metrics for requests made through the diagnostic client.

```dart
final client = DiagnosticHttpClient();

try {
  final response = await client.get(
    Uri.parse('https://example.com/api'),
  );

  debugPrint('Status code: ${response.statusCode}');
} finally {
  client.close();
}
```

### 📡 What can it track?

- 📤 Outgoing request body bytes.
- 📥 Incoming response body bytes.
- 🧭 Network activity associated with diagnostic routes, subject to the implementation's attribution behavior.

> ⚠️ These measurements are not necessarily total network usage. They may exclude headers, TLS overhead, retransmissions, and traffic sent through other HTTP clients or networking APIs.

## 📊 Diagnostic Sessions

Start a diagnostic session using the controller:

```dart
final controller = DeviceDiagnostics.controller;

await controller.start();
```

When you have finished collecting diagnostics, export the session report:

```dart
await controller.stopAndExportPdf(
  share: false,
);
```

### 🔁 Typical workflow

1. ▶️ Start a diagnostic session.
2. 📈 Reproduce the performance issue or user-reported bug.
3. 🧭 Navigate through the relevant screens.
4. ⏹️ Stop the session and generate the report.
5. 📄 Inspect or share the PDF, depending on your configuration.

## 📄 PDF Diagnostic Reports

Generate a report to help investigate performance issues and reproduce bugs.

Depending on the data collected and platform support, reports can include:

- 📱 Device and operating-system information.
- ⚡ CPU and 🧠 memory measurements.
- 🎬 Frame-performance observations.
- 🌐 Recorded network byte metrics.
- 🧭 Screen visits and session timing.
- 📋 Diagnostic samples and summary information.

> 📝 Reports contain diagnostic data from the recorded session. Review the contents before sharing them, especially if they may reveal information about your application or its usage.

## 🧭 Route Tracking

Add the package's route observer to your `MaterialApp`:

```dart
MaterialApp(
  navigatorObservers: [
    DeviceDiagnostics.routeObserver,
  ],
  home: const MyHomePage(),
);
```

This allows the package to observe supported navigation events and associate diagnostic activity with routes.

> 💡 For the clearest route names, use named routes where appropriate. Route attribution may depend on how navigation is implemented.

## 📱 Platform Support

Platform support depends on the metric and the underlying operating-system APIs.

| Metric | 🤖 Android | 🍎 iOS |
|---|---|---|
| Device information | ✅ Supported fields | ✅ Supported fields |
| Memory usage | ✅ Where available | ✅ Where available |
| Process CPU estimate | ✅ Where available | ✅ Where available |
| Network type | ✅ Where available | ✅ Where available |
| Network byte counters | ✅ Where available | ⚠️ May be unavailable |
| Thermal state | ✅ On supported Android versions | ✅ On supported iOS versions |
| Frame monitoring | 📊 Flutter-side monitoring | 📊 Flutter-side monitoring |
| PDF report generation | 📄 Subject to package/platform support | 📄 Subject to package/platform support |

**Legend:** ✅ Available where implemented · ⚠️ Limited or unavailable · 📊 Collected by Flutter-side instrumentation

## 🏗️ Architecture Overview

The package is organized into layers:

- 🎛️ **Configuration** — controls visibility and metric options.
- 🧠 **Diagnostic controller** — manages session state, sampling, and collected data.
- 📱 **Native integrations** — retrieve platform-specific metrics through a method channel.
- 🌐 **Network instrumentation** — records HTTP traffic passing through the provided client.
- 🧭 **Route observer** — tracks supported navigation events.
- 🖥️ **Diagnostic overlay** — displays diagnostic controls and information.
- 📄 **Report generator** — produces PDF diagnostic reports.

## 🔒 Privacy and Performance Considerations

- 🔐 Enable diagnostics intentionally, especially in Release builds.
- 📋 Review diagnostic reports before sharing them.
- 🌐 Remember that only traffic passing through the instrumented client can be counted by that client.
- ⚙️ Choose a sampling interval suitable for your workload.
- 🧪 Validate performance and metric behavior on real devices.
- 🛡️ Do not use UI visibility settings as access control for sensitive diagnostic information.

## 🛠️ Troubleshooting

### ❓ The diagnostic overlay is not visible

- ✅ Verify that the selected `DiagnosticVisibility` matches the current build mode.
- ⚙️ Initialize the package before `runApp()`.
- 🧩 Ensure your app is wrapped using `DeviceDiagnostics.observability()`.
- 🔎 Confirm that the idle floating button setting matches your expectations.

### ❓ Some metrics are missing

- 📱 Support varies by platform and operating-system version.
- 🔐 Some native APIs require permissions or return unavailable values.
- 🌐 iOS network byte counters may not be available through the current implementation.
- 🧪 Test on a physical device when emulator results are incomplete.

### ❓ No network activity is recorded

- 🌐 Make requests through `DiagnosticHttpClient`.
- 🔎 Confirm that network monitoring is enabled.
- ⚠️ Traffic from unrelated clients and networking APIs may not be captured.

## 🧑‍💻 Development

Run the project's checks before submitting changes:

```bash
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

## 🗺️ Roadmap

Potential future improvements include:

- 📈 More diagnostic visualizations.
- 🧪 Expanded automated tests.
- 📱 Broader platform-specific metric support.
- 📄 Additional report customization.
- 🔍 More detailed performance insights.

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome!

1. 🍴 Fork the repository.
2. 🌿 Create a feature branch.
3. 🛠️ Implement and test your changes.
4. 📬 Submit a pull request with a clear description.

## 📬 Support

Found a bug or have a feature request?

- 🐛 [Report an issue](https://github.com/rajatdas-dev/device_diagnostics/issues)
- 💻 [View the GitHub repository](https://github.com/rajatdas-dev/device_diagnostics)
- 📦 [View the package on pub.dev](https://pub.dev/packages/device_diagnostics)

## 📜 License

This package is distributed under the [MIT License](LICENSE).

---

Made with ❤️ and Flutter by **Rajat Das**.
