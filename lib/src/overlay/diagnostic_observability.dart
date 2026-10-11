
import 'package:flutter/widgets.dart';

import '../config/diagnostic_config.dart';
import '../core/diagnostic_controller.dart';
import '../navigation/diagnostic_route_observer.dart';
import 'diagnostic_overlay.dart';

export '../config/diagnostic_config.dart';
export '../navigation/diagnostic_route_observer.dart';

class DeviceDiagnostics {
  DeviceDiagnostics._();

  static DiagnosticController get controller =>
      DiagnosticController.instance;

  static final DiagnosticRouteObserver routeObserver =
  DiagnosticRouteObserver();

  static Future<void> initialize({
    DiagnosticConfig? config,
  }) {
    return controller.initialize(
      config: config ?? const DiagnosticConfig(),
    );
  }

  /// Wrap the root application with diagnostic observability.
  ///
  /// Example:
  /// DeviceDiagnostics.observability(
  ///   config: const DiagnosticConfig(
  ///     visibility: DiagnosticVisibility.debugAndRelease,
  ///   ),
  ///   child: MaterialApp(...),
  /// )
  static Widget observability({
    required Widget child,
    DiagnosticConfig? config,
  }) {
    return DiagnosticObservability(
      config: config,
      child: child,
    );
  }
}

class DiagnosticObservability extends StatefulWidget {
  const DiagnosticObservability({
    super.key,
    required this.child,
    this.config,
  });

  final Widget child;
  final DiagnosticConfig? config;

  @override
  State<DiagnosticObservability> createState() =>
      _DiagnosticObservabilityState();
}

class _DiagnosticObservabilityState
    extends State<DiagnosticObservability> {
  @override
  void initState() {
    super.initState();

    // initialize assigns the configuration before its Future completes.
    // This ensures the first build checks the intended visibility mode.
    DiagnosticController.instance.initialize(
      config: widget.config,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = DiagnosticController.instance;

    if (!controller.config.isVisibleInCurrentBuild) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            DiagnosticOverlay(
              bounds: Size(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
            ),
          ],
        );
      },
    );
  }
}
