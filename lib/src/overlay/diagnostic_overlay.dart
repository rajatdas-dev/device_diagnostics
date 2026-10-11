
import 'package:flutter/material.dart';

import '../core/diagnostic_controller.dart';

class DiagnosticOverlay extends StatefulWidget {
  const DiagnosticOverlay({super.key, required this.bounds});

  final Size bounds;

  @override
  State<DiagnosticOverlay> createState() => _DiagnosticOverlayState();
}

class _DiagnosticOverlayState extends State<DiagnosticOverlay>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFF111827);
  static const Color _surface = Color(0xFF1F2937);
  static const Color _border = Color(0xFF374151);
  static const Color _accent = Color(0xFF60A5FA);
  static const Color _success = Color(0xFF34D399);
  static const Color _muted = Color(0xFF9CA3AF);

  static const double _collapsedWidth = 132;
  static const double _collapsedHeight = 48;
  static const double _expandedWidth = 286;

  Offset position = const Offset(12, 110);

  bool expanded = false;
  bool _isExporting = false;

  String? reportPath;
  String? reportError;

  @override
  Widget build(BuildContext context) {
    final controller = DiagnosticController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.config.showFloatingButtonWhenIdle &&
            !controller.isRecording) {
          return const SizedBox.shrink();
        }

        final safePosition = _boundedPosition(expanded);

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          left: safePosition.dx,
          top: safePosition.dy,
          child: Material(
            color: Colors.transparent,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topLeft,
              child: expanded
                  ? _buildExpandedPanel(controller)
                  : _buildFloatingPill(controller),
            ),
          ),
        );
      },
    );
  }

  Offset _boundedPosition(bool isExpanded) {
    final width = isExpanded ? _expandedWidth : _collapsedWidth;
    final height = isExpanded ? 500.0 : _collapsedHeight;

    final maxX = (widget.bounds.width - width).clamp(0.0, double.infinity);
    final maxY = (widget.bounds.height - height).clamp(0.0, double.infinity);

    return Offset(
      position.dx.clamp(0.0, maxX).toDouble(),
      position.dy.clamp(0.0, maxY).toDouble(),
    );
  }

  void _moveOverlay(DragUpdateDetails details) {
    setState(() {
      position = Offset(
        position.dx + details.delta.dx,
        position.dy + details.delta.dy,
      );
    });
  }

  Widget _buildFloatingPill(DiagnosticController controller) {
    final latest = controller.samples.isEmpty
        ? null
        : controller.samples.last;

    final fps = latest?.fps;

    return GestureDetector(
      onPanUpdate: _moveOverlay,
      onTap: () {
        setState(() => expanded = true);
      },
      child: Semantics(
        button: true,
        label: controller.isRecording
            ? 'Diagnostics recording. Open dashboard.'
            : 'Open diagnostics dashboard',
        child: Container(
          width: _collapsedWidth,
          height: _collapsedHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: controller.isRecording ? _success : _accent,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIAGNOSTICS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.isRecording
                                ? _success
                                : _muted,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            controller.isRecording
                                ? (fps == null
                                ? 'Recording'
                                : '${fps.toStringAsFixed(0)} FPS')
                                : 'Idle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: _muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(DiagnosticController controller) {
    final latest = controller.samples.isEmpty
        ? null
        : controller.samples.last;

    final maxPanelHeight =
    (widget.bounds.height - 24).clamp(180.0, 520.0).toDouble();

    return Container(
      width: _expandedWidth,
      constraints: BoxConstraints(maxHeight: maxPanelHeight),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(controller),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionStatus(controller),
                  const SizedBox(height: 14),
                  const Text(
                    'LIVE METRICS',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricCard(
                        icon: Icons.memory_rounded,
                        label: 'MEMORY',
                        value: _formatMemory(latest?.memoryBytes),
                        color: const Color(0xFFA78BFA),
                      ),
                      _metricCard(
                        icon: Icons.speed_rounded,
                        label: 'CPU',
                        value: latest?.cpuPercent == null
                            ? '—'
                            : '${latest!.cpuPercent!.toStringAsFixed(1)}%',
                        color: _accent,
                      ),
                      _metricCard(
                        icon: Icons.show_chart_rounded,
                        label: 'FRAME RATE',
                        value: latest?.fps == null
                            ? '—'
                            : '${latest!.fps!.toStringAsFixed(1)} FPS',
                        color: _success,
                      ),
                      _metricCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'DROPPED FRAMES',
                        value: latest?.droppedFrames?.toString() ?? '—',
                        color: const Color(0xFFFBBF24),
                      ),
                      _metricCard(
                        icon: Icons.wifi_rounded,
                        label: 'NETWORK',
                        value: latest?.networkType ?? '—',
                        color: const Color(0xFF38BDF8),
                      ),
                      _metricCard(
                        icon: Icons.thermostat_rounded,
                        label: 'THERMAL STATE',
                        value: latest?.thermalState ?? '—',
                        color: const Color(0xFFFB923C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    Icons.smartphone_rounded,
                    'Current screen',
                    controller.currentRoute,
                  ),
                  _buildInfoRow(
                    Icons.data_usage_rounded,
                    'Samples collected',
                    controller.samples.length.toString(),
                  ),
                  if (reportPath != null) ...[
                    const SizedBox(height: 10),
                    _buildMessage(
                      icon: Icons.check_circle_outline_rounded,
                      color: _success,
                      text: 'Report saved: $reportPath',
                    ),
                  ],
                  if (reportError != null) ...[
                    const SizedBox(height: 10),
                    _buildMessage(
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFF87171),
                      text: 'Export failed: $reportError',
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildPrimaryAction(controller),
                  const SizedBox(height: 8),
                  _buildSecondaryAction(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DiagnosticController controller) {
    return GestureDetector(
      onPanUpdate: _moveOverlay,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 8, 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: _accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Diagnostics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isRecording
                        ? 'Session in progress'
                        : 'Performance monitor',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.drag_indicator_rounded,
                color: _muted, size: 20),
            IconButton(
              tooltip: 'Collapse diagnostics',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => expanded = false),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStatus(DiagnosticController controller) {
    final recording = controller.isRecording;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (recording ? _success : _accent).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: (recording ? _success : _accent).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            recording ? Icons.radio_button_checked : Icons.pause_circle_outline,
            size: 19,
            color: recording ? _success : _accent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording ? 'Recording active' : 'No active session',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recording
                      ? 'Collecting diagnostic samples'
                      : 'Start a session to collect data',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (recording)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _success,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 124,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(DiagnosticController controller) {
    final recording = controller.isRecording;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: recording
              ? const Color(0xFFB45353)
              : const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        onPressed: _isExporting
            ? null
            : () => _handleSessionAction(controller),
        icon: _isExporting
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(
          recording
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline_rounded,
          size: 20,
        ),
        label: Text(
          _isExporting
              ? 'Exporting report...'
              : recording
              ? 'Stop & Export PDF'
              : 'Start Session',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: _isExporting
            ? null
            : () => setState(() => expanded = false),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.minimize_rounded, size: 17),
        label: const Text(
          'Minimize overlay',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemory(int? bytes) {
    if (bytes == null) return '—';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _handleSessionAction(
      DiagnosticController controller,
      ) async {
    if (_isExporting) return;

    if (!controller.isRecording) {
      setState(() {
        reportPath = null;
        reportError = null;
      });

      try {
        controller.start();
      } catch (error) {
        if (!mounted) return;
        setState(() => reportError = error.toString());
      }
      return;
    }

    setState(() {
      _isExporting = true;
      reportError = null;
      reportPath = null;
    });

    try {
      final path = await controller.stopAndExportPdf();

      if (!mounted) return;
      setState(() {
        reportPath = path;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        reportError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
