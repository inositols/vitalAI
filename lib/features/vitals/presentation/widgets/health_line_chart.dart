import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/vital_record.dart';

class HealthLineChart extends StatelessWidget {
  final String activeTab;
  final List<VitalRecord> records;

  const HealthLineChart({
    super.key,
    required this.activeTab,
    required this.records,
  });

  String get chartTitle {
    switch (activeTab) {
      case 'bp':
        return 'Blood Pressure Trend';
      case 'glucose':
        return 'Blood Glucose Control';
      case 'pulse':
        return 'Pulse Rate (BPM)';
      case 'temp':
        return 'Body Temperature';
      case 'weight':
        return 'Weight Progress';
      default:
        return 'Health Trends';
    }
  }

  Color get activeColor {
    switch (activeTab) {
      case 'bp':
        return AppColors.bpVital;
      case 'glucose':
        return AppColors.glucoseVital;
      case 'pulse':
        return AppColors.pulseVital;
      case 'temp':
        return AppColors.tempVital;
      case 'weight':
        return AppColors.weightVital;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(20.0),
      borderRadius: AppRadius.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chartTitle,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time graphical metrics',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (activeTab == 'bp') ...[
                Row(
                  children: [
                    _buildLegendItem('Sys', AppColors.bpVital),
                    const SizedBox(width: 8),
                    _buildLegendItem('Dia', AppColors.primary),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: SizedBox(
              key: ValueKey<String>(activeTab),
              height: 260,
              child: records.isEmpty
                  ? const Center(
                      child: Text(
                        'No vital entries recorded in this range.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : LineChart(_buildChartData(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final isDark = context.isDarkMode;
    final List<FlSpot> spots1 = [];
    final List<FlSpot> spots2 = [];

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final double xVal = i.toDouble();

      if (activeTab == 'bp' && r.systolic != null && r.diastolic != null) {
        spots1.add(FlSpot(xVal, r.systolic!));
        spots2.add(FlSpot(xVal, r.diastolic!));
      } else if (activeTab == 'glucose' && r.glucoseValue != null) {
        spots1.add(FlSpot(xVal, r.glucoseValue!));
      } else if (activeTab == 'pulse' && r.pulseRate != null) {
        spots1.add(FlSpot(xVal, r.pulseRate!));
      } else if (activeTab == 'temp' && r.bodyTemperature != null) {
        spots1.add(FlSpot(xVal, r.bodyTemperature!));
      } else if (activeTab == 'weight' && r.weight != null) {
        spots1.add(FlSpot(xVal, r.weight!));
      }
    }

    final isBp = activeTab == 'bp';
    final primaryColor = activeColor;
    final secondaryColor = AppColors.primary;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (val) => FlLine(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: (records.length / 5).clamp(1.0, 10.0),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < records.length) {
                final dt = records[idx].dateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${dt.month}/${dt.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots1.isEmpty ? [const FlSpot(0, 0)] : spots1,
          isCurved: true,
          color: primaryColor,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 3,
              strokeColor: primaryColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.25),
                primaryColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        if (isBp && spots2.isNotEmpty)
          LineChartBarData(
            spots: spots2,
            isCurved: true,
            color: secondaryColor,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: secondaryColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withValues(alpha: 0.2),
                  secondaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
      ],
    );
  }
}
