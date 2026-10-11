import 'package:flutter/material.dart';
import '../core/diagnostic_controller.dart';
import '../config/diagnostic_config.dart';
import '../navigation/diagnostic_route_observer.dart';
import 'diagnostic_overlay.dart';

// Re-export types referenced by the convenient facade.
export '../config/diagnostic_config.dart';
export '../navigation/diagnostic_route_observer.dart';

class DeviceDiagnostics {
  DeviceDiagnostics._();
  static DiagnosticController get controller => DiagnosticController.instance;

  static Future<void> initialize({DiagnosticConfig? config}) =>
      controller.initialize(config: config ?? DiagnosticConfig());
  static final DiagnosticRouteObserver routeObserver =
      DiagnosticRouteObserver();

  /// Wrap the root app, e.g. `DeviceDiagnostics.observability(child: MaterialApp(...))`.
  static Widget observability({required Widget child}) =>
      DiagnosticObservability(child: child);
}

class DiagnosticObservability extends StatelessWidget {
  const DiagnosticObservability({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final controller = DiagnosticController.instance;
    if (!controller.config.isVisibleInCurrentBuild) return child;
    return LayoutBuilder(
        builder: (context, constraints) =>
            Stack(fit: StackFit.expand, children: <Widget>[
              child,
              DiagnosticOverlay(
                  bounds: Size(constraints.maxWidth, constraints.maxHeight))
            ]));
  }
}
