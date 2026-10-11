import 'package:flutter/material.dart';
import '../core/diagnostic_controller.dart';

class DiagnosticOverlay extends StatefulWidget {
  const DiagnosticOverlay({super.key, required this.bounds});
  final Size bounds;
  @override
  State<DiagnosticOverlay> createState() => _DiagnosticOverlayState();
}

class _DiagnosticOverlayState extends State<DiagnosticOverlay> {
  Offset position = const Offset(12, 110);
  bool expanded = false;
  String? reportPath;
  String? reportError;
  @override
  Widget build(BuildContext context) {
    final c = DiagnosticController.instance;
    return AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          if (!c.config.showFloatingButtonWhenIdle && !c.isRecording) {
            return const SizedBox.shrink();
          }
          return Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onPanUpdate: (details) => setState(() => position = Offset(
                      (position.dx + details.delta.dx)
                          .clamp(0, widget.bounds.width - 90)
                          .toDouble(),
                      (position.dy + details.delta.dy)
                          .clamp(0, widget.bounds.height - 70)
                          .toDouble())),
                  child: Container(
                    width: expanded ? 250 : 56,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xEE18212F),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ]),
                    child: expanded
                        ? _panel(c)
                        : IconButton(
                            tooltip: 'Device diagnostics',
                            onPressed: () => setState(() => expanded = true),
                            icon: Icon(
                                c.isRecording
                                    ? Icons.monitor_heart
                                    : Icons.bug_report,
                                color: Colors.white)),
                  ),
                ),
              ));
        });
  }

  Widget _panel(DiagnosticController c) {
    final latest = c.samples.isEmpty ? null : c.samples.last;
    String mb(int? bytes) =>
        bytes == null ? 'N/A' : '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            const Expanded(
                child: Text('Diagnostics',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            IconButton(
                onPressed: () => setState(() => expanded = false),
                icon: const Icon(Icons.close, color: Colors.white, size: 18))
          ]),
          _metric('Screen', c.currentRoute),
          _metric('Memory', mb(latest?.memoryBytes)),
          _metric(
              'CPU',
              latest?.cpuPercent == null
                  ? 'N/A'
                  : '${latest!.cpuPercent!.toStringAsFixed(1)}%'),
          _metric(
              'FPS',
              latest?.fps == null
                  ? 'Sampling…'
                  : latest!.fps!.toStringAsFixed(1)),
          _metric('Network', latest?.networkType ?? 'N/A'),
          _metric('Thermal', latest?.thermalState ?? 'N/A'),
          const SizedBox(height: 8),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: c.isRecording
                      ? () async {
                          try {
                            final path = await c.stopAndExportPdf();
                            if (mounted) {
                              setState(() {
                                reportPath = path;
                                reportError = null;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => reportError = e.toString());
                            }
                          }
                        }
                      : () {
                          setState(() {
                            reportPath = null;
                            reportError = null;
                          });
                          c.start();
                        },
                  child: Text(
                      c.isRecording ? 'Stop & export PDF' : 'Start session'))),
          if (c.isRecording)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Samples: ${c.samples.length}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11))),
          if (reportPath != null)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Saved: $reportPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10))),
          if (reportError != null)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Report error: $reportError',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 10))),
        ]);
  }

  Widget _metric(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: <Widget>[
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)))
      ]));
}
