
# Contributing

Thank you for your interest in contributing to `device_diagnostics`!

## Before You Start

- Check existing issues and pull requests before starting work.
- For major changes, open an issue to discuss the proposal first.
- Keep diagnostic collection opt-in.
- Document platform-specific limitations and unavailable metrics.
- Do not introduce collection of credentials, sensitive request bodies, or data from unrelated applications.

## Development Setup

1. Install Flutter on the stable channel.
2. Clone the repository.
3. From the project root, run:

   ```bash
   flutter pub get
   ```

## Before Submitting Changes

Run these commands:

```bash
dart format lib test example
flutter analyze
flutter test
```

For platform-specific changes, test the affected platform where practical.

## Pull Requests

- Explain the problem and the purpose of your change.
- Include tests for bug fixes and new features where practical.
- Update `CHANGELOG.md` for user-facing changes.
- Update the README and examples when public APIs or behavior change.
- Keep changes focused and avoid unrelated modifications.

## Reporting Bugs

Include the Flutter and Dart versions, operating system, affected package version, reproduction steps, expected behavior, actual behavior, and sanitized logs.

Never include passwords, access tokens, API keys, or private user data in an issue.
