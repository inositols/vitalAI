import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';

/// Dynamic interactive GenUI line chart widget embedded in AI chat for trend visualization.
/// Features touch tooltips, clinical target reference baselines, axis labels, Hero transitions, and haptic feedback.
class GenUiTrendChartWidget extends StatelessWidget {
  final GenUiTrendChartModel model;

  const GenUiTrendChartWidget({
    super.key,
    required this.model,
  });

  Color _metricColor() {
    final lower = model.metricType.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('systolic')) {
      return AppColors.bpVital;
    } else if (lower.contains('glucose') || lower.contains('sugar')) {
      return AppColors.glucoseVital;
    } else if (lower.contains('pulse') || lower.contains('heart') || lower.contains('hr')) {
      return AppColors.pulseVital;
    } else if (lower.contains('spo2') || lower.contains('oxygen')) {
      return AppColors.spo2Vital;
    } else if (lower.contains('temp')) {
      return AppColors.tempVital;
    } else if (lower.contains('weight')) {
      return AppColors.weightVital;
    }
    return AppColors.primary;
  }

  IconData _metricIcon() {
    final lower = model.metricType.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure')) {
      return AppIcons.bloodPressure;
    } else if (lower.contains('glucose') || lower.contains('sugar')) {
      return AppIcons.glucose;
    } else if (lower.contains('pulse') || lower.contains('heart')) {
      return AppIcons.pulse;
    } else if (lower.contains('spo2') || lower.contains('oxygen')) {
      return AppIcons.spo2;
    } else if (lower.contains('temp')) {
      return AppIcons.temperature;
    } else if (lower.contains('weight')) {
      return AppIcons.weight;
    }
    return Icons.show_chart_rounded;
  }

  String _metricUnit() {
    final lower = model.metricType.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure')) return 'mmHg';
    if (lower.contains('glucose') || lower.contains('sugar')) return 'mg/dL';
    if (lower.contains('pulse') || lower.contains('heart')) return 'BPM';
    if (lower.contains('spo2') || lower.contains('oxygen')) return '%';
    if (lower.contains('temp')) return '°F';
    if (lower.contains('weight')) return 'kg';
    return '';
  }

  double? _targetBaseline() {
    final lower = model.metricType.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure')) return 120.0;
    if (lower.contains('glucose') || lower.contains('sugar')) return 100.0;
    if (lower.contains('spo2') || lower.contains('oxygen')) return 95.0;
    return null;
  }

  String? _targetLabel() {
    final lower = model.metricType.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure')) return 'AHA: 120';
    if (lower.contains('glucose') || lower.contains('sugar')) return 'Fasting: <100';
    if (lower.contains('spo2') || lower.contains('oxygen')) return 'Normal: ≥95%';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _metricColor();
    final unit = _metricUnit();
    final target = _targetBaseline();
    final targetName = _targetLabel();

    final points = model.dataPoints.isEmpty ? [120.0, 122.0, 118.0] : model.dataPoints;
    final labels = model.labels.isEmpty
        ? List.generate(points.length, (i) => 'P${i + 1}')
        : model.labels;

    final spots = <FlSpot>[];
    double minY = points.first;
    double maxY = points.first;

    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i]));
      if (points[i] < minY) minY = points[i];
      if (points[i] > maxY) maxY = points[i];
    }

    if (target != null) {
      minY = math.min(minY, target);
      maxY = math.max(maxY, target);
    }

    final paddingY = (maxY - minY) * 0.2;
    final chartMinY = (minY - (paddingY == 0 ? 5 : paddingY)).floorToDouble();
    final chartMaxY = (maxY + (paddingY == 0 ? 5 : paddingY)).ceilToDouble();

    final latestValue = points.isNotEmpty ? points.last : 0.0;
    final heroTag = 'genui_trend_${model.metricType}_${model.title.hashCode}';

    return Semantics(
      label:
          '${model.title}. Historical progression: ${points.map((p) => p.toStringAsFixed(0)).join(', ')} $unit. Latest reading: ${latestValue.toStringAsFixed(1)} $unit.',
      container: true,
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.2,
              ),
              boxShadow: AppShadows.subtle(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header: Icon, Title, and Latest Reading Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_metricIcon(), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  model.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
                ),
                child: Text(
                  'Latest: ${latestValue.toStringAsFixed(latestValue.truncateToDouble() == latestValue ? 0 : 1)} $unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive Line Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent || event is FlPanDownEvent) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final label = idx < labels.length ? labels[idx] : 'Point';
                        final valStr = spot.y.toStringAsFixed(spot.y.truncateToDouble() == spot.y ? 0 : 1);
                        return LineTooltipItem(
                          '$label\n$valStr $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: ((chartMaxY - chartMinY) / 3).clamp(1.0, 50.0),
                      getTitlesWidget: (val, meta) {
                        if (val == meta.min || val == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          val.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[idx],
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (target != null)
                      HorizontalLine(
                        y: target,
                        color: AppColors.success.withValues(alpha: 0.6),
                        strokeWidth: 1.2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 4, bottom: 2),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                          labelResolver: (line) => targetName ?? 'Target',
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clinical Summary Insight Callout
          if (model.summary != null && model.summary!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.insights_rounded, size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.summary!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    ),
    ),
    );
  }
}
