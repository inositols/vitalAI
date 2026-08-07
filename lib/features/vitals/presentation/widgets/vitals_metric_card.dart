import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import 'sparkline_painter.dart';

class VitalsMetricCard extends StatelessWidget {
  final String metricType;
  final String patientId;

  const VitalsMetricCard({
    super.key,
    required this.metricType,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<VitalsBloc, VitalsState>(
      builder: (context, state) {
        if (state is VitalsLoading) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is VitalsLoadSuccess) {
          final records = state.records;
          bool isMmol = false;
          try {
            isMmol = context.watch<SettingsBloc>().state.glucoseUnit == 'mmol/L';
          } catch (_) {}

          if (metricType == 'bp') {
            final bpRecords = records.where((r) => r.systolic != null && r.diastolic != null).toList();
            if (bpRecords.isEmpty) {
              return _buildEmptyCard(theme, 'Blood Pressure', AppIcons.bloodPressure, 'No readings logged yet.');
            }
            final latest = bpRecords.first;
            final systolic = latest.systolic!;
            final diastolic = latest.diastolic!;
            final isAbnormal = systolic >= 130 || systolic < 90 || diastolic >= 85 || diastolic < 60;
            final statusColor = isAbnormal ? theme.colorScheme.error : const Color(0xFF008A5E);

            final sparklinePoints = bpRecords
                .take(5)
                .map((r) => r.systolic!)
                .toList()
                .reversed
                .toList();

            return _buildTile(
              context: context,
              title: 'Blood Pressure',
              value: '${systolic.toInt()}/${diastolic.toInt()}',
              unit: 'mmHg',
              statusText: isAbnormal ? 'Abnormal' : 'Normal',
              statusColor: statusColor,
              icon: AppIcons.bloodPressure,
              iconColor: Colors.red,
              timeString: _formatDateTime(latest.dateTime),
              sparklinePoints: sparklinePoints,
            );
          } else {
            final glucoseRecords = records.where((r) => r.glucoseValue != null).toList();
            if (glucoseRecords.isEmpty) {
              return _buildEmptyCard(theme, 'Blood Glucose', AppIcons.glucose, 'No readings logged yet.');
            }
            final latest = glucoseRecords.first;
            final glucose = latest.glucoseValue!;
            final isAbnormal = glucose >= 140 || glucose < 70;
            final statusColor = isAbnormal ? theme.colorScheme.error : const Color(0xFF008A5E);
            final mealContext = latest.glucoseMealContext ?? 'Random';

            final displayGlucose = isMmol ? (glucose / 18.018) : glucose;
            final valueText = isMmol ? displayGlucose.toStringAsFixed(1) : '${glucose.toInt()}';

            final sparklinePoints = glucoseRecords
                .take(5)
                .map((r) => isMmol ? (r.glucoseValue! / 18.018) : r.glucoseValue!)
                .toList()
                .reversed
                .toList();

            return _buildTile(
              context: context,
              title: 'Blood Glucose',
              value: valueText,
              unit: isMmol ? 'mmol/L' : 'mg/dL',
              statusText: '${isAbnormal ? 'Abnormal' : 'Normal'} (${mealContext[0].toUpperCase()}${mealContext.substring(1)})',
              statusColor: statusColor,
              icon: AppIcons.glucose,
              iconColor: Colors.orange,
              timeString: _formatDateTime(latest.dateTime),
              sparklinePoints: sparklinePoints,
            );
          }
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyCard(ThemeData theme, String title, IconData icon, String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              radius: 24,
              child: Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required String statusText,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
    required String timeString,
    required List<double> sparklinePoints,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: () => context.go('/charts'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(timeString, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                            const SizedBox(width: 4),
                            Text(unit, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                          ),
                          child: Text(statusText, style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  if (sparklinePoints.length >= 2)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: CustomPaint(
                          painter: SparklinePainter(points: sparklinePoints, lineColor: iconColor),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final difference = DateTime.now().difference(dt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}
