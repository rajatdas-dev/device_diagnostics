
import 'dart:io';
import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/diagnostic_controller.dart';

class DiagnosticPdfReport {
  Future<String> generate({
    required DiagnosticController controller,
    bool share = false,
  }) async {
    final doc = pw.Document();
    final samples = controller.samples.toList();
    final start = controller.sessionStartedAt;
    final end = controller.sessionEndedAt;

    final duration = start != null && end != null
        ? end.difference(start)
        : Duration.zero;

    final baseline = samples.isNotEmpty
        ? samples.first.timestamp
        : start;

    double? average(Iterable<double?> values) {
      final valid = values.whereType<double>().toList();
      if (valid.isEmpty) return null;
      return valid.reduce((a, b) => a + b) / valid.length;
    }

    double? peak(Iterable<double?> values) {
      final valid = values.whereType<double>().toList();
      if (valid.isEmpty) return null;
      return valid.reduce(math.max);
    }

    double? minimum(Iterable<double?> values) {
      final valid = values.whereType<double>().toList();
      if (valid.isEmpty) return null;
      return valid.reduce(math.min);
    }

    String number(double? value, {String suffix = ''}) {
      return value == null ? 'Unavailable' : '${value.toStringAsFixed(1)}$suffix';
    }

    String bytesLabel(double bytes) {
      if (bytes >= 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MiB';
      }
      if (bytes >= 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KiB';
      }
      return '${bytes.toStringAsFixed(0)} B';
    }

    String elapsedLabel(Duration value) {
      final hours = value.inHours;
      final minutes = value.inMinutes.remainder(60);
      final seconds = value.inSeconds.remainder(60);

      if (hours > 0) {
        return '${hours}h ${minutes}m ${seconds}s';
      }
      if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${seconds}s';
    }

    double elapsedSeconds(DateTime timestamp) {
      if (baseline == null) return 0;
      return timestamp.difference(baseline).inMilliseconds / 1000.0;
    }

    List<_MetricPoint> metricPoints(double? Function(dynamic) read) {
      return samples
          .map((sample) {
        final value = read(sample);
        if (value == null) return null;
        return _MetricPoint(
          elapsedSeconds(sample.timestamp),
          value,
        );
      })
          .whereType<_MetricPoint>()
          .toList();
    }

    final memoryMiB = metricPoints(
          (sample) => sample.memoryBytes == null
          ? null
          : sample.memoryBytes! / (1024 * 1024),
    );

    final cpuPoints = metricPoints(
          (sample) => sample.cpuPercent,
    );

    final fpsPoints = metricPoints(
          (sample) => sample.fps,
    );

    // rxBytes and txBytes are per-sample deltas in this package.
    // Convert them to cumulative traffic for the timeline.
    var rxTotal = 0;
    var txTotal = 0;
    final networkRx = <_MetricPoint>[];
    final networkTx = <_MetricPoint>[];

    for (final sample in samples) {
      rxTotal += sample.rxBytes ?? 0;
      txTotal += sample.txBytes ?? 0;

      final x = elapsedSeconds(sample.timestamp);
      if (sample.rxBytes != null) {
        networkRx.add(_MetricPoint(x, rxTotal.toDouble()));
      }
      if (sample.txBytes != null) {
        networkTx.add(_MetricPoint(x, txTotal.toDouble()));
      }
    }

    final totalTraffic = rxTotal + txTotal;
    final networkScale = totalTraffic >= 1024 * 1024
        ? 1024.0 * 1024.0
        : 1024.0;

    final networkUnit = totalTraffic >= 1024 * 1024 ? 'MiB' : 'KiB';

    final scaledRx = networkRx
        .map((point) => _MetricPoint(point.x, point.y / networkScale))
        .toList();
    final scaledTx = networkTx
        .map((point) => _MetricPoint(point.x, point.y / networkScale))
        .toList();

    // Thermal states are categories, not measured temperatures.
    // Give each observed state a category index and print the mapping.
    final thermalStates = samples
        .map((sample) => sample.thermalState)
        .whereType<String>()
        .where((state) => state.trim().isNotEmpty)
        .toSet()
        .toList();

    final thermalIndex = <String, double>{
      for (var i = 0; i < thermalStates.length; i++)
        thermalStates[i]: i.toDouble(),
    };

    final thermalPoints = <_MetricPoint>[
      for (final sample in samples)
        if (sample.thermalState != null &&
            thermalIndex.containsKey(sample.thermalState))
          _MetricPoint(
            elapsedSeconds(sample.timestamp),
            thermalIndex[sample.thermalState]!,
          ),
    ];

    final rxSum = samples.fold<int>(
      0,
          (sum, sample) => sum + (sample.rxBytes ?? 0),
    );
    final txSum = samples.fold<int>(
      0,
          (sum, sample) => sum + (sample.txBytes ?? 0),
    );

    final memoryValues = samples
        .where((sample) => sample.memoryBytes != null)
        .map((sample) => sample.memoryBytes! / (1024 * 1024));

    final cpuValues = samples.map((sample) => sample.cpuPercent);
    final fpsValues = samples.map((sample) => sample.fps);

    final device = controller.deviceMetadata;

    pw.Widget sectionTitle(String title, String subtitle) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey600,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget metricCard(
        String label,
        String value,
        String detail,
        PdfColor accent,
        ) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border(
            left: pw.BorderSide(color: accent, width: 3),
          ),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              detail,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey600,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget summaryRow(List<pw.Widget> cards) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) pw.SizedBox(width: 8),
            pw.Expanded(child: cards[i]),
          ],
        ],
      );
    }

    pw.Widget infoLine(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 125,
              child: pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blueGrey600,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget chartCard({
      required String title,
      required String subtitle,
      required List<_MetricPoint> points,
      required PdfColor color,
      required String yAxisLabel,
      String? emptyMessage,
    }) {
      if (points.length < 2) {
        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                emptyMessage ??
                    'Not enough supported samples to draw this timeline.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blueGrey600,
                ),
              ),
            ],
          ),
        );
      }

      final maxX = math.max(
        points.map((point) => point.x).reduce(math.max),
        1.0,
      );
      final maxY = points.map((point) => point.y).reduce(math.max);
      final minY = points.map((point) => point.y).reduce(math.min);

      // Use a readable scale derived from the actual peak.
      final yAxisMax = _niceAxisMaximum(maxY);
      final yTicks = _axisTicks(yAxisMax);

      final xTicks = <double>[0, maxX / 2, maxX];

      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.SizedBox(
              height: 170,
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: pw.FixedAxis<double>(xTicks),
                  yAxis: pw.FixedAxis<double>(yTicks),
                ),
                datasets: [
                  pw.LineDataSet<pw.PointChartValue>(
                    legend: yAxisLabel,
                    color: color,
                    lineWidth: 2,
                    drawPoints: points.length <= 30,
                    data: points
                        .map(
                          (point) => pw.PointChartValue(point.x, point.y),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'X axis: elapsed time (seconds)',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blueGrey600,
                  ),
                ),
                pw.Text(
                  'Y axis: $yAxisLabel',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blueGrey600,
                  ),
                ),
              ],
            ),
            if (minY < 0)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  'Values include negative measurements.',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 38, 34, 42),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Device Diagnostics • Generated report',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blueGrey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blueGrey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Cover and session summary.
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DEVICE DIAGNOSTICS',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.lightBlue200,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Performance Report',
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${start?.toLocal().toString().split('.').first ?? 'Start time unavailable'}'
                      '  —  '
                      '${end?.toLocal().toString().split('.').first ?? 'End time unavailable'}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Duration: ${elapsedLabel(duration)}   •   Samples: ${samples.length}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
              ],
            ),
          ),

          sectionTitle(
            'At a glance',
            'Summary statistics calculated from available session samples.',
          ),

          summaryRow([
            metricCard(
              'Avg. memory',
              number(average(memoryValues), suffix: ' MiB'),
              'Min ${number(minimum(memoryValues), suffix: ' MiB')}'
                  ' • Peak ${number(peak(memoryValues), suffix: ' MiB')}',
              PdfColors.blue,
            ),
            metricCard(
              'Avg. CPU',
              number(average(cpuValues), suffix: '%'),
              'Peak ${number(peak(cpuValues), suffix: '%')}',
              PdfColors.orange,
            ),
            metricCard(
              'Avg. FPS',
              number(average(fpsValues)),
              'Peak ${number(peak(fpsValues))} FPS',
              PdfColors.green,
            ),
          ]),

          pw.SizedBox(height: 8),

          summaryRow([
            metricCard(
              'Received',
              bytesLabel(rxSum.toDouble()),
              'Instrumented/native counter deltas',
              PdfColors.cyan,
            ),
            metricCard(
              'Sent',
              bytesLabel(txSum.toDouble()),
              'Instrumented/native counter deltas',
              PdfColors.purple,
            ),
            metricCard(
              'Samples',
              '${samples.length}',
              'Collected during this session',
              PdfColors.blueGrey,
            ),
          ]),

          sectionTitle(
            'Device information',
            'Metadata supplied by the current platform implementation.',
          ),

          infoLine('Device model', device['model']?.toString() ?? 'Unavailable'),
          infoLine(
            'Manufacturer',
            device['manufacturer']?.toString() ?? 'Unavailable',
          ),
          infoLine('Operating system', device['osVersion']?.toString() ?? 'Unavailable'),
          infoLine('System on chip', device['soc']?.toString() ?? 'Unavailable'),
          infoLine(
            'Architecture',
            device['architecture']?.toString() ?? 'Unavailable',
          ),
          infoLine(
            'Hardware decoder',
            device['hardwareDecoder']?.toString() ?? 'Unavailable',
          ),

          sectionTitle(
            'Performance timelines',
            'Each chart uses elapsed session time on the X axis. Vertical scales are based on the observed data.',
          ),

          chartCard(
            title: 'Memory usage',
            subtitle: 'Resident memory samples converted to MiB.',
            points: memoryMiB,
            color: PdfColors.blue,
            yAxisLabel: 'Memory (MiB)',
          ),

          chartCard(
            title: 'CPU utilization',
            subtitle: 'CPU percentages reported by the platform.',
            points: cpuPoints,
            color: PdfColors.orange,
            yAxisLabel: 'CPU (%)',
          ),

          chartCard(
            title: 'Frame rate',
            subtitle: 'Estimated frames per second from collected frame timings.',
            points: fpsPoints,
            color: PdfColors.green,
            yAxisLabel: 'Frames per second (FPS)',
          ),

          chartCard(
            title: 'Network traffic',
            subtitle:
            'Cumulative received and sent byte deltas observed during the session. Scale: $networkUnit.',
            points: scaledRx,
            color: PdfColors.cyan,
            yAxisLabel: 'Received ($networkUnit)',
            emptyMessage:
            'Not enough received-byte samples to draw a timeline. Network counters may be unavailable on this platform.',
          ),

          chartCard(
            title: 'Network traffic — sent',
            subtitle: 'Cumulative sent-byte deltas observed during the session.',
            points: scaledTx,
            color: PdfColors.purple,
            yAxisLabel: 'Sent ($networkUnit)',
            emptyMessage:
            'Not enough sent-byte samples to draw a timeline. Network counters may be unavailable on this platform.',
          ),

          if (thermalPoints.length >= 2)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                chartCard(
                  title: 'Thermal state timeline',
                  subtitle:
                  'Categorical state index over elapsed time; this is not a temperature chart.',
                  points: thermalPoints,
                  color: PdfColors.red,
                  yAxisLabel: 'Thermal category index',
                ),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Thermal category legend',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      for (var i = 0; i < thermalStates.length; i++)
                        pw.Text(
                          '${i.toString()}: ${thermalStates[i]}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
              ],
            )
          else
            chartCard(
              title: 'Thermal state timeline',
              subtitle: 'Thermal states are categorical, not temperature readings.',
              points: thermalPoints,
              color: PdfColors.red,
              yAxisLabel: 'Thermal category index',
              emptyMessage:
              'Not enough thermal-state samples are available to plot a timeline.',
            ),

          sectionTitle(
            'Screen visits',
            'Routes observed by the configured Navigator observer.',
          ),

          if (controller.screenVisits.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text(
                'No screen visits were recorded. Add DeviceDiagnostics.routeObserver '
                    'to MaterialApp.navigatorObservers to enable route tracking.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Route', 'Duration', 'Received', 'Sent'],
              data: controller.screenVisits.map((visit) {
                return [
                  visit.route,
                  elapsedLabel(visit.duration),
                  bytesLabel(visit.rxBytes.toDouble()),
                  bytesLabel(visit.txBytes.toDouble()),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder(
                horizontalInside: const pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                bottom: const pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
            ),

          sectionTitle(
            'Interpretation and limitations',
            'Read these notes alongside the charts.',
          ),

          pw.Bullet(
            text:
            'Unavailable values are omitted from calculations; they are not treated as zero.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
            'CPU, memory, FPS, and thermal measurements depend on platform support and sampling conditions.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
            'Thermal categories are shown as state indices with a legend. They do not represent degrees or measured temperature.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
            'Network charts accumulate available per-sample byte deltas. Missing deltas are not independently measurable traffic.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
            'DiagnosticHttpClient observes only requests made through that client. It does not capture all application or device traffic.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
            'Route attribution applies to the package’s recorded route and instrumented traffic; it does not identify traffic from unrelated apps.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final reports = Directory('${dir.path}/device_diagnostics');

    if (!await reports.exists()) {
      await reports.create(recursive: true);
    }

    final file = File(
      '${reports.path}/diagnostics_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await doc.save(), flush: true);

    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Device diagnostics report',
      );
    }

    return file.path;
  }
}

class _MetricPoint {
  const _MetricPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Returns a rounded-up, human-readable axis maximum based on the data peak.
double _niceAxisMaximum(double peak) {
  if (!peak.isFinite || peak <= 0) return 1;

  final roughStep = peak / 4;
  final magnitude = math.pow(10, (math.log(roughStep) / math.ln10).floor());
  final normalized = roughStep / magnitude;

  final niceStep = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;

  final step = niceStep * magnitude;
  return ((peak / step).ceil() * step).toDouble();
}

/// Produces evenly spaced axis ticks starting at zero.
List<double> _axisTicks(double maximum) {
  if (!maximum.isFinite || maximum <= 0) return [0, 1];

  return [
    0,
    maximum / 4,
    maximum / 2,
    maximum * 3 / 4,
    maximum,
  ];
}
