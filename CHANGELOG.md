# Changelog

All notable changes to `device_diagnostics` are documented in this file.

## [0.0.7]

### Added
- 📊 Added enhanced PDF performance report summaries with average, minimum, and peak metric statistics.
- 📈 Improved performance timelines for memory usage, CPU utilization, frame rate, network traffic, and thermal state.
- 📉 Added minimum metric statistics to provide additional insight into observed performance.

### Changed
- 🎨 Redesigned the floating diagnostic overlay with a more modern dashboard interface.
- 🖥️ Improved metric presentation with dedicated cards for memory, CPU, FPS, dropped frames, network type, and thermal state.
- 🟢 Improved recording status visibility and session controls.
- 📄 Improved PDF report presentation with a structured summary, device information, performance charts, screen visit details, and measurement limitations.
- 🌐 Improved network traffic visualization by accumulating available per-sample received and sent byte deltas.
- 📐 Improved chart axis scaling for clearer performance timelines.

### Fixed
- 🛠️ Fixed numeric type compatibility in PDF chart axis calculations.
- 🧹 Removed unused-code warnings by incorporating minimum statistics into the PDF summary.

## [0.0.6]

### Fixed
- 🐛 Fixed the `No Overlay widget found` error when the diagnostic overlay is displayed outside the application's `MaterialApp` overlay hierarchy.
- 🛠️ Improved diagnostic overlay integration by providing an appropriate `Overlay` ancestor for overlay-dependent widgets, including tooltips.
- 🔧 Improved compatibility with Flutter applications that wrap `MaterialApp` using `DeviceDiagnostics.observability`.
- ♻️ Improved overlay lifecycle handling to support reliable rendering and updates.

## [0.0.5]

### Fixed
- 🐛 Fixed the `Directionality` assertion triggered by the diagnostic overlay's `Stack` when no ancestor provides text direction.
- 🧭 Added a fallback text direction to support applications that wrap `MaterialApp` with `DeviceDiagnostics.observability`.
- 🛠️ Updated stack alignment to use `Alignment.topLeft`, removing the stack's dependency on directional alignment.
- 🔧 Improved diagnostic overlay compatibility with Flutter's widget hierarchy.

## [0.0.4]

### Fixed
- 🐛 Fixed the missing `Directionality` issue in the diagnostic overlay when used above `MaterialApp`.
- 🧭 Added a fallback text direction to ensure the diagnostic overlay can resolve directional alignment when no ancestor provides `Directionality`.
- 🛠️ Improved diagnostic overlay compatibility with Flutter's inherited widget system.

## [0.0.3]

### Fixed
- 🐛 Fixed a `Directionality` error in the diagnostic overlay that occurred when the overlay was built without an ancestor providing text direction.
- 🧭 Improved overlay compatibility with Flutter applications using `MaterialApp` and inherited widget configurations.

## [0.0.2]

### Added
- 📚 Expanded the README with detailed installation and usage instructions.
- 🎙️ Documented all diagnostic visibility modes: `debug`, `profile`, `release`, `debugAndRelease`, and `all`.
- ⚙️ Added explanations for configuration options and diagnostic session management.
- 🌐 Improved documentation for HTTP network instrumentation.
- 📄 Expanded PDF reporting and platform support documentation.
- 🔐 Added privacy, performance, and troubleshooting guidance.
- 🎨 Improved README presentation with emojis, badges, and clearer section organization.

### Changed
- 📝 Improved the overall documentation structure and readability.
- 💡 Clarified platform-dependent metric availability and network instrumentation limitations.

## [0.0.1] - Initial Release

### Added
- 🚀 Initial release of the `device_diagnostics` Flutter package.
- 📊 Diagnostic session management and configurable metric collection.
- 📱 Device and platform metric reporting where supported.
- ⚡ Frame performance monitoring where enabled and supported.
- 🌐 Network instrumentation for requests made through `DiagnosticHttpClient`.
- 🧭 Screen route visit tracking through the route observer.
- 📄 PDF diagnostic report generation and optional sharing.
- 🛠️ Diagnostic overlay and observability integration.
- ⚙️ Configuration options for diagnostic visibility and sampling behavior.

### Notes
- Metric availability depends on the operating system and platform implementation.
- Unsupported metrics may be unavailable.
- Network instrumentation observes only traffic covered by the configured instrumentation.
- Diagnostic measurements may vary depending on platform support, sampling conditions, and application workload.