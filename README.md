# device_diagnostics

A session-based Flutter diagnostics package with a draggable overlay, app-level HTTP instrumentation, route timing, native platform metrics, and local PDF reports.

## Status

This is an initial implementation scaffold. Run `flutter analyze`, `flutter test`, and build on real Android and iOS devices before production use. Native metrics are platform-dependent and may be unavailable. Do not interpret missing metrics as zero.

## Quick start

```dart
import 'package:device_diagnostics/device_diagnostics.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeviceDiagnostics.initialize(
    config: const DiagnosticConfig(visibility: DiagnosticVisibility.debug),
  );
  runApp(DeviceDiagnostics.observability(
    child: MaterialApp(
      navigatorObservers: [DeviceDiagnostics.routeObserver],
      home: const MyHomePage(),
    ),
  ));
}
```

Visibility values: `debug` (default), `release`, `both`. These control overlay visibility, not Flutter's compilation mode. Avoid enabling production diagnostics without user consent and a privacy review.

## Instrument HTTP traffic

Only requests made through this client are counted:

```dart
final client = DiagnosticHttpClient();
final response = await client.get(Uri.parse('https://example.com/api'));
client.close();
```

Use your own app's supported HTTP integration patterns; other clients, native libraries, WebViews, and unrelated apps are not automatically counted. The current route is used for attribution when the request body is consumed.

## Start/stop

The floating panel starts collection when Start is pressed. Stop ends sampling and writes a PDF under the app documents directory at `device_diagnostics/`. The report is saved under the app documents directory and the platform share sheet is opened by default. Call `stopAndExportPdf(share: false)` through the controller if you only want to save locally.

## Collected metrics and limitations

| Metric | Android | iOS |
|---|---|---|
| App/process memory | PSS estimate from `Debug.getPss()` | Resident memory via `task_info` |
| CPU | `/proc/self/stat` estimate; tick frequency assumption should be validated per target | Not implemented; reported unavailable |
| FPS/frame timing | Flutter frame timing callback | Flutter frame timing callback |
| Network type | Active transport | `NWPathMonitor` |
| System byte counters | UID counters, cumulative since boot; deltas can include other app components sharing UID | Not exposed by this plugin; unavailable |
| Instrumented HTTP bytes | Requests through `DiagnosticHttpClient` | Same |
| Thermal | Android 10+ thermal status | iOS 11+ thermal state |
| Model/OS | Android build properties | Machine identifier and iOS version |
| SoC | `Build.SOC_MODEL` on Android 12+ | Not exposed; unavailable |
| Hardware decoder | Not a device-wide property; unavailable | Not exposed; unavailable |

Android traffic counters may be unsupported or cumulative since boot. The current sample uses deltas between samples; the first delta is intentionally unavailable. System counters are not per-route. Per-route attribution is currently available for instrumented HTTP traffic only, and precise attribution around overlapping requests is approximate because it uses the active route at completion.

The package cannot inspect all background apps or arbitrary device activity. Android thermal status is a coarse state, not a temperature measurement. iOS does not expose general process CPU usage or device-wide network byte totals to ordinary apps.

## Performance design

- Collectors are started only when a session starts.
- Default sampling interval is one second (minimum 250 ms).
- The overlay updates from one controller and does not rebuild the host app's widget subtree intentionally.
- The PDF is generated after recording stops.

Sampling itself has overhead. Validate battery, CPU and memory overhead on low-end devices before production use.

## Permissions and privacy

Android requests `ACCESS_NETWORK_STATE`; no runtime permission is required for active transport. Do not log credentials, request bodies, full URLs containing identifiers, or personal data. Diagnostic reports may contain device and usage metadata; obtain consent and provide a deletion/sharing policy if shipping to end users.

## Development

```sh
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter run
```

## Roadmap

- Add robust Android CPU normalization from per-process CPU time and device core count.
- Improve per-route request attribution using request-start route context and explicit network event records.
- Add optional chart exports and report sharing controls.
- Add iOS process CPU metrics if a reliable, supported implementation is validated.
- Add real-device integration tests for thermal and network transitions.
