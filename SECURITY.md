
# Security Policy

## Supported Versions

Security fixes are intended for the latest published version of
`device_diagnostics`.

Users should upgrade to the latest version before reporting an issue
where possible.

## Reporting a Vulnerability

Please do not disclose security vulnerabilities in public issues.

If GitHub private vulnerability reporting is enabled, use the repository's
Security tab to report the issue privately.

Otherwise, contact the repository maintainer through a private contact
method listed on the repository profile.

Please include:

- The affected package version and platform.
- A description of the potential security impact.
- Reproduction steps or a proof of concept.
- Suggested mitigation, if known.

Do not include real user data, credentials, access tokens, or other secrets.

## Privacy and Diagnostic Collection

`device_diagnostics` is intended to collect diagnostic metrics only when
enabled by the integrating application.

Report any behavior that unexpectedly collects or exposes sensitive
information. Diagnostic reports should distinguish unavailable metrics
from zero values and document platform-specific limitations.
