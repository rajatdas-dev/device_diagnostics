# Changelog

All notable changes to `device_diagnostics` are documented in this file.

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
- 🎚️ Documented all diagnostic visibility modes: `debug`, `profile`, `release`, `debugAndRelease`, and `all`.
- ⚙️ Added explanations for configuration options and diagnostic session management.
- 🌐 Improved documentation for HTTP network instrumentation.
- 📄 Expanded PDF reporting and platform support documentation.
- 🔒 Added privacy, performance, and troubleshooting guidance.
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