import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/vital_record.dart';

/// Interactive Line Chart for VitalAI using `fl_chart`.
/// Features smooth cubic spline curves, gradient underlays, dynamic axes, and interactive touch tooltips.
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
      case 'spo2':
        return 'Oxygen (SpO₂)';
      case 'temp':
        return 'Body Temperature';
      case 'weight':
        return 'Weight Progress';
      default:
        return 'Health Trends';
    }
  }

  String get metricUnit {
    switch (activeTab) {
      case 'bp':
        return 'mmHg';
      case 'glucose':
        return 'mg/dL';
      case 'pulse':
        return 'BPM';
      case 'spo2':
        return '%';
      case 'temp':
        return '°C';
      case 'weight':
        return 'kg';
      default:
        return '';
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
      case 'spo2':
        return AppColors.spo2Vital;
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

    // Filter records that have data for the activeTab
    final validRecords = records.where((r) {
      switch (activeTab) {
        case 'bp':
          return r.systolic != null && r.diastolic != null;
        case 'glucose':
          return r.glucoseValue != null;
        case 'pulse':
          return r.pulseRate != null;
        case 'spo2':
          return r.oxygenSaturation != null;
        case 'temp':
          return r.bodyTemperature != null;
        case 'weight':
          return r.weight != null;
        default:
          return false;
      }
    }).toList();

    return AppCard(
      padding: const EdgeInsets.all(18.0),
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
                      fontSize: 16.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Interactive fl_chart metrics',
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
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: SizedBox(
              key: ValueKey<String>(activeTab),
              height: 240,
              child: validRecords.isEmpty
                  ? const Center(
                      child: Text(
                        'No readings recorded in this range.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : LineChart(_buildChartData(context, validRecords)),
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

  LineChartData _buildChartData(BuildContext context, List<VitalRecord> validRecords) {
    final isDark = context.isDarkMode;
    final List<FlSpot> spots1 = [];
    final List<FlSpot> spots2 = [];

    for (int i = 0; i < validRecords.length; i++) {
      final r = validRecords[i];
      final double xVal = i.toDouble();

      if (activeTab == 'bp' && r.systolic != null && r.diastolic != null) {
        spots1.add(FlSpot(xVal, r.systolic!));
        spots2.add(FlSpot(xVal, r.diastolic!));
      } else if (activeTab == 'glucose' && r.glucoseValue != null) {
        spots1.add(FlSpot(xVal, r.glucoseValue!));
      } else if (activeTab == 'pulse' && r.pulseRate != null) {
        spots1.add(FlSpot(xVal, r.pulseRate!));
      } else if (activeTab == 'spo2' && r.oxygenSaturation != null) {
        spots1.add(FlSpot(xVal, r.oxygenSaturation!));
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
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          tooltipRoundedRadius: 10,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final idx = spot.x.toInt();
              final dt = idx >= 0 && idx < validRecords.length ? validRecords[idx].dateTime : null;
              final timeStr = dt != null ? '${dt.month}/${dt.day}' : '';
              final valStr = spot.y.toStringAsFixed(activeTab == 'temp' || activeTab == 'weight' ? 1 : 0);

              return LineTooltipItem(
                '$valStr $metricUnit\n$timeStr',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (val, meta) {
              return Text(
                val.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: (validRecords.length / 5).clamp(1.0, 10.0),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < validRecords.length) {
                final dt = validRecords[idx].dateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
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
          curveSmoothness: 0.35,
          color: primaryColor,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: validRecords.length <= 15,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: primaryColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.22),
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
            curveSmoothness: 0.35,
            color: secondaryColor,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: validRecords.length <= 15,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: secondaryColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withValues(alpha: 0.18),
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
