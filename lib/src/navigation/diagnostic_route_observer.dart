import 'package:flutter/widgets.dart';
import '../core/diagnostic_controller.dart';

class DiagnosticRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final settings = route?.settings;
    DiagnosticController.instance.onRouteChanged(
        settings?.name ?? route?.runtimeType.toString() ?? 'Unknown');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }
}
