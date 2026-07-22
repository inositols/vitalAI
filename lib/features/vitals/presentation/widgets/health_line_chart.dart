import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
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
        return 'Blood Pressure History';
      case 'glucose':
        return 'Blood Glucose Trends';
      case 'pulse':
        return 'Heart Rate (BPM)';
      case 'temp':
        return 'Body Temperature';
      case 'weight':
        return 'Weight Progress & BMI';
      default:
        return 'Health Trends';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartTitle,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: SizedBox(
              key: ValueKey<String>(activeTab),
              height: 260,
              child: records.isEmpty
                  ? const Center(child: Text('No data recorded in this range.'))
                  : LineChart(_buildChartData(context)),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
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

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (val) => FlLine(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (records.length / 5).clamp(1.0, 10.0),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < records.length) {
                final dt = records[idx].dateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${dt.month}/${dt.day}',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: context.colorScheme.onSurfaceVariant,
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
          color: isBp ? Colors.redAccent : context.colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: (isBp ? Colors.redAccent : context.colorScheme.primary)
                .withValues(alpha: 0.1),
          ),
        ),
        if (isBp && spots2.isNotEmpty)
          LineChartBarData(
            spots: spots2,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}
