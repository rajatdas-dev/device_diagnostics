import 'package:device_diagnostics/device_diagnostics.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeviceDiagnostics.initialize(
      config: DiagnosticConfig(visibility: DiagnosticVisibility.debug));
  runApp(
      DeviceDiagnostics.observability(

      child: const ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Diagnostics Example',
        navigatorObservers: <NavigatorObserver>[
          DeviceDiagnostics.routeObserver
        ],
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Diagnostics example')),
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Text('Use the floating bug icon to start a session.'),
        const SizedBox(height: 12),
        ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/details'),
                builder: (_) => const DetailsPage())),
            child: const Text('Open details'))
      ])));
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Time spent on this route is tracked.')));
}
