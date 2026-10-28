import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_tokens.dart';

/// Clinical Blood Pressure Comparison Chart Card matching Screen 7 in the concept image.
/// Displays double-trendline (Last 7 days vs Previous 7 days) and latest reading summary.
class ClinicalComparisonChartCard extends StatelessWidget {
  final String patientName;
  final String latestReading;
  final String latestTimestamp;

  const ClinicalComparisonChartCard({
    super.key,
    this.patientName = 'Chika Okafor',
    this.latestReading = '118/76 mmHg',
    this.latestTimestamp = 'Apr 26, 2025 • 09:41 AM',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Blood Pressure Trend',
                style: AppTypography.titleMedium(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildLegendItem(
                color: AppColors.primary,
                label: 'Last 7 days',
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: const Color(0xFF94A3B8),
                label: 'Previous 7 days',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FlChart Line Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 30,
                      reservedSize: 30,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        final days = ['19', '20', '21', '22', '23', '24', '25', '26'];
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[idx],
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 60,
                maxY: 150,
                lineBarsData: [
                  // Last 7 days (Teal)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 128),
                      FlSpot(1, 125),
                      FlSpot(2, 126),
                      FlSpot(3, 118),
                      FlSpot(4, 122),
                      FlSpot(5, 124),
                      FlSpot(6, 120),
                      FlSpot(7, 118),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  // Previous 7 days (Gray)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 134),
                      FlSpot(1, 130),
                      FlSpot(2, 132),
                      FlSpot(3, 128),
                      FlSpot(4, 130),
                      FlSpot(5, 126),
                      FlSpot(6, 125),
                      FlSpot(7, 124),
                    ],
                    isCurved: true,
                    color: const Color(0xFF94A3B8),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 2.5,
                          color: Colors.white,
                          strokeWidth: 1.5,
                          strokeColor: const Color(0xFF94A3B8),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Latest Reading Bottom Strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkContainer : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Reading',
                      style: AppTypography.labelSmall(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latestReading,
                      style: AppTypography.titleMedium(
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  latestTimestamp,
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
