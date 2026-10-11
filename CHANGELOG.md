# Changelog

All notable changes to `device_diagnostics` are documented in this file.

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
