import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/genui_component_model.dart';
import '../../theme/design_tokens.dart';

/// GenUI Interactive Comparison Chart for comparing 2 periods or 2 metrics over time.
class ComparisonChartWidget extends StatelessWidget {
  final GenUiComparisonChartModel model;

  const ComparisonChartWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s1 = model.series1Data.isEmpty ? [120.0, 122.0, 118.0] : model.series1Data;
    final s2 = model.series2Data.isEmpty ? [128.0, 126.0, 124.0] : model.series2Data;
    final labels = model.labels.isEmpty ? ['Log 1', 'Log 2', 'Log 3'] : model.labels;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                model.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(context, model.series1Name, AppColors.primary),
              const SizedBox(width: 16),
              _buildLegendItem(context, model.series2Name, AppColors.tertiary),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                fontSize: 10,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(s1.length, (i) => FlSpot(i.toDouble(), s1[i])),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: List.generate(s2.length, (i) => FlSpot(i.toDouble(), s2[i])),
                    isCurved: true,
                    color: AppColors.tertiary,
                    barWidth: 3,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          if (model.comparisonNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                model.comparisonNote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
