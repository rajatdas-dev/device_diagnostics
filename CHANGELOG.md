# Changelog

All notable changes to `device_diagnostics` are documented in this file.

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
- Initial release of the `device_diagnostics` Flutter package.
- Diagnostic session management and configurable metric collection.
- Device and platform metric reporting where supported.
- Frame performance monitoring where enabled and supported.
- Network instrumentation for requests made through `DiagnosticHttpClient`.
- Screen route visit tracking through the route observer.
- PDF diagnostic report generation and optional sharing.
- Diagnostic overlay and observability integration.
- Configuration options for diagnostic visibility and sampling behavior.

### Notes
- Metric availability depends on the operating system and platform implementation.
- Unsupported metrics may be unavailable.
- HTTP instrumentation covers only requests routed through `DiagnosticHttpClient`.
- Diagnostic collection should be enabled explicitly by the integrating application.