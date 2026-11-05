import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';

/// Clinical chart card displaying actual recorded vital trends, with date-range filters & contextual actions.
class ChartCard extends StatefulWidget {
  final GenUiComponent component;
  final GenUiActionCallback? onActionSelected;

  const ChartCard({
    super.key,
    required this.component,
    this.onActionSelected,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  String _selectedRange = '7D';

  @override
  Widget build(BuildContext context) {
    final data = widget.component.data;
    final title = widget.component.title ?? 'Vital Signs Trend';
    final metric = data['metric']?.toString() ?? data['metricType']?.toString() ?? 'Blood Pressure';
    final latestReading = data['latestReading']?.toString() ?? data['latest']?.toString();
    final unit = data['unit']?.toString() ?? '';

    // Extract data points
    final rawPoints = data['dataPoints'] as List? ?? data['readings'] as List? ?? [];
    final List<double> points = [];
    for (final p in rawPoints) {
      if (p is num) points.add(p.toDouble());
    }

    final bool hasSufficientData = points.length >= 2;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    if (latestReading != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Latest: $latestReading $unit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Date Range Selector Chips
              Row(
                children: ['7D', '14D', '30D'].map((range) {
                  final isSelected = _selectedRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedRange = range);
                        widget.onActionSelected?.call(GenUiAction(
                          id: 'change_date_range_$range',
                          type: GenUiActionType.changeDateRange,
                          label: range,
                          payload: {'range': range},
                        ));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.lightContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Chart Body or Graceful Limitation Warning
          if (hasSufficientData)
            _buildChartArea(points)
          else
            _buildInsufficientDataNotice(metric),
          const SizedBox(height: 14),
          // Contextual Actions: Compare readings, View individual readings, Generate summary
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChartActionButton(
                label: 'Compare readings',
                icon: Icons.compare_arrows_rounded,
                actionType: GenUiActionType.compareVitals,
              ),
              _buildChartActionButton(
                label: 'View individual readings',
                icon: Icons.table_chart_outlined,
                actionType: GenUiActionType.viewIndividualReadings,
              ),
              _buildChartActionButton(
                label: 'Generate summary',
                icon: Icons.summarize_rounded,
                actionType: GenUiActionType.generateSummary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea(List<double> points) {
    return Container(
      height: 130,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: CustomPaint(
        painter: _SimpleTrendLinePainter(points: points, strokeColor: AppColors.primary),
      ),
    );
  }

  Widget _buildInsufficientDataNotice(String metric) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.lightContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.lightTextMuted, size: 24),
          const SizedBox(height: 6),
          Text(
            'Insufficient historical data for $metric.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'At least 2 verified readings are required to plot an accurate clinical trend. Additional records will populate this chart automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartActionButton({
    required String label,
    required IconData icon,
    required GenUiActionType actionType,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: AppColors.primary),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
      backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        widget.onActionSelected?.call(GenUiAction(
          id: label.toLowerCase().replaceAll(' ', '_'),
          type: actionType,
          label: label,
        ));
      },
    );
  }
}

class _SimpleTrendLinePainter extends CustomPainter {
  final List<double> points;
  final Color strokeColor;

  _SimpleTrendLinePainter({required this.points, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 20) + 10);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SimpleTrendLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.strokeColor != strokeColor;
}

