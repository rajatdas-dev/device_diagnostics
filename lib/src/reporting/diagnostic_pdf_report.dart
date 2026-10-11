import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/diagnostic_controller.dart';

class DiagnosticPdfReport {
  Future<String> generate(
      {required DiagnosticController controller, bool share = false}) async {
    final doc = pw.Document();
    final start = controller.sessionStartedAt;
    final end = controller.sessionEndedAt;
    final duration =
        start == null || end == null ? Duration.zero : end.difference(start);
    final samples = controller.samples;
    double? average(Iterable<double?> values) {
      final v = values.whereType<double>().toList();
      if (v.isEmpty) return null;
      return v.reduce((a, b) => a + b) / v.length;
    }

    String fmt(double? v, String suffix) =>
        v == null ? 'Unavailable' : '${v.toStringAsFixed(1)}$suffix';
    final memoryValues = samples
        .where((s) => s.memoryBytes != null)
        .map((s) => s.memoryBytes! / 1048576)
        .toList();
    doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
              pw.Header(level: 0, child: pw.Text('Device Diagnostics Report')),
              pw.Text(
                  'Session: ${start?.toIso8601String() ?? 'Unknown'} to ${end?.toIso8601String() ?? 'Unknown'}'),
              pw.Text(
                  'Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s  |  Samples: ${samples.length}'),
              pw.SizedBox(height: 12),
              pw.Header(level: 1, child: pw.Text('Summary')),
              pw.TableHelper.fromTextArray(headers: <String>[
                'Metric',
                'Average / Details'
              ], data: <List<String>>[
                <String>[
                  'Memory (MiB)',
                  memoryValues.isEmpty
                      ? 'Unavailable'
                      : '${average(memoryValues.map((v) => v))!.toStringAsFixed(1)} average; ${memoryValues.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} peak'
                ],
                <String>[
                  'CPU',
                  fmt(average(samples.map((s) => s.cpuPercent)), '%')
                ],
                <String>[
                  'FPS',
                  fmt(average(samples.map((s) => s.fps)), ' FPS')
                ],
                <String>[
                  'Network type',
                  samples
                      .map((s) => s.networkType)
                      .whereType<String>()
                      .toSet()
                      .join(', ')
                      .ifEmpty('Unavailable')
                ],
                <String>[
                  'Thermal states',
                  samples
                      .map((s) => s.thermalState)
                      .whereType<String>()
                      .toSet()
                      .join(', ')
                      .ifEmpty('Unavailable')
                ],
                <String>[
                  'Device model',
                  controller.deviceMetadata['model']?.toString() ??
                      'Unavailable'
                ],
                <String>[
                  'Manufacturer',
                  controller.deviceMetadata['manufacturer']?.toString() ??
                      'Unavailable'
                ],
                <String>[
                  'OS version',
                  controller.deviceMetadata['osVersion']?.toString() ??
                      'Unavailable'
                ],
                <String>[
                  'SoC',
                  controller.deviceMetadata['soc']?.toString() ?? 'Unavailable'
                ],
                <String>[
                  'Architecture',
                  controller.deviceMetadata['architecture']?.toString() ??
                      'Unavailable'
                ],
                <String>[
                  'Hardware decoder',
                  controller.deviceMetadata['hardwareDecoder']?.toString() ??
                      'Unavailable'
                ],
              ]),
              pw.SizedBox(height: 12),
              pw.Header(level: 1, child: pw.Text('Memory timeline (MiB)')),
              if (memoryValues.length >= 2)
                pw.SizedBox(
                    height: 160,
                    child: pw.Chart(
                        // pw.LineChart(
                        //     <pw.LineChartSeries<pw.PointChartValue>>[pw.LineChartSeries<pw.PointChartValue>(
                        //         data: memoryValues.asMap().entries.map((e) => pw.PointChartValue(
                        //             e.key.toDouble(), e.value)).toList(),
                        //         xAxis: pw.NumericAxis(),
                        //         yAxis: pw.NumericAxis())])
                        grid: pw.CartesianGrid(
                            xAxis: pw.FixedAxis<double>(<double>[
                              0,
                              (memoryValues.length - 1) / 2,
                              (memoryValues.length - 1).toDouble()
                            ]),
                            yAxis: pw.FixedAxis<double>(<double>[
                              memoryValues.reduce((a, b) => a < b ? a : b),
                              memoryValues.reduce((a, b) => a > b ? a : b) + 1,
                            ])),
                        datasets: <pw.Dataset>[
                          pw.LineDataSet<pw.PointChartValue>(
                              legend: "Memory (MiB)",
                              color: PdfColors.blue,
                              lineWidth: 2,
                              drawPoints: true,
                              data: memoryValues.asMap().entries.map((entry) {
                                return pw.PointChartValue(
                                    entry.key.toDouble(), entry.value);
                              }).toList())
                        ])),
              if (memoryValues.length < 2)
                pw.Text(
                    'Not enough supported samples to plot a memory timeline.'),
              pw.Header(level: 1, child: pw.Text('Screen visits')),
              if (controller.screenVisits.isEmpty)
                pw.Text(
                    'No route visits were recorded. Add DeviceDiagnostics.routeObserver to MaterialApp.navigatorObservers.'),
              if (controller.screenVisits.isNotEmpty)
                pw.TableHelper.fromTextArray(
                    headers: <String>[
                      'Route',
                      'Duration (s)',
                      'RX bytes',
                      'TX bytes'
                    ],
                    data: controller.screenVisits
                        .map((v) => <String>[
                              v.route,
                              (v.duration.inMilliseconds / 1000)
                                  .toStringAsFixed(1),
                              '${v.rxBytes}',
                              '${v.txBytes}'
                            ])
                        .toList()),
              pw.SizedBox(height: 12),
              pw.Header(level: 1, child: pw.Text('Raw samples')),
              pw.TableHelper.fromTextArray(
                  headers: <String>[
                    'Time',
                    'Memory B',
                    'CPU %',
                    'FPS',
                    'RX B',
                    'TX B',
                    'Network',
                    'Thermal'
                  ],
                  data: samples
                      .map((s) => <String>[
                            s.timestamp.toIso8601String(),
                            '${s.memoryBytes ?? 'N/A'}',
                            s.cpuPercent?.toStringAsFixed(1) ?? 'N/A',
                            s.fps?.toStringAsFixed(1) ?? 'N/A',
                            '${s.rxBytes ?? 'N/A'}',
                            '${s.txBytes ?? 'N/A'}',
                            s.networkType ?? 'N/A',
                            s.thermalState ?? 'N/A'
                          ])
                      .toList()),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Limitations: metrics are platform-dependent. Missing values are reported as unavailable, not zero. Network totals from the native system counters may be UID-wide/cumulative and do not identify individual screens. Instrumented HTTP bytes include only requests using DiagnosticHttpClient. CPU, SoC and decoder metadata may be unavailable. This report does not inspect unrelated apps.'),
            ]));
    final dir = await getApplicationDocumentsDirectory();
    final reports = Directory('${dir.path}/device_diagnostics');
    if (!await reports.exists()) await reports.create(recursive: true);
    final file = File(
        '${reports.path}/diagnostics_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    if (share) {
      await Share.shareXFiles(<XFile>[XFile(file.path)],
          text: 'Device diagnostics report');
    }
    return file.path;
  }
}

extension _NonEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
