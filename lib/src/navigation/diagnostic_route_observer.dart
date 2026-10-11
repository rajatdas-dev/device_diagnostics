
import 'package:flutter/widgets.dart';

import '../core/diagnostic_controller.dart';

class DiagnosticRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final routeName =
        route?.settings.name ?? route?.runtimeType.toString() ?? 'Unknown';

    DiagnosticController.instance.onRouteChanged(routeName);
  }

  @override
  void didPush(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    super.didRemove(route, previousRoute);
    _update(previousRoute);
  }
}
