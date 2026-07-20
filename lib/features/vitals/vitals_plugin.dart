import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitalai/core/database/db_service.dart';
import '../../core/plugin/module.dart';
import 'domain/repositories/vitals_repository.dart';
import 'data/repositories/vitals_repository_impl.dart';
import 'presentation/bloc/vitals_bloc.dart';
import 'presentation/bloc/vitals_state.dart';
import '../settings/presentation/bloc/settings_bloc.dart';
import '../settings/presentation/bloc/settings_state.dart';

/// Pluggable health vitals module registration wrapper.
class VitalsPlugin implements VitalModule {
  @override
  String get id => 'vitals';

  @override
  String get name => 'Health Vitals';

  @override
  IconData get icon => Icons.favorite;

  @override
  void registerDependencies(GetIt locator) {
    locator.registerLazySingleton<VitalsRepository>(
      () => VitalsRepositoryImpl(locator<DbService>()),
    );
    locator.registerFactory(
      () => VitalsBloc(vitalsRepository: locator<VitalsRepository>()),
    );
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: '/vitals/add',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("Add Vital Reading Screen"))),
    ),
  ];

  @override
  List<Widget> buildDashboardCards(BuildContext context, String patientId) {
    // Return dynamic metric card components bound to real vitals records
    return [
      _VitalsMetricCard(metricType: 'bp', patientId: patientId),
      _VitalsMetricCard(metricType: 'glucose', patientId: patientId),
    ];
  }

  @override
  Future<pw.Widget?> buildReportSection(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Build a neat PDF text section for report rendering
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Health Vitals Log Summary",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "Report shows recorded blood pressure, blood glucose, temperature, pulse rate, oxygen saturation and body weight trends between ${startDate.toLocal()} and ${endDate.toLocal()}.",
          ),
        ],
      ),
    );
  }
}

class _VitalsMetricCard extends StatelessWidget {
  final String metricType;
  final String patientId;

  const _VitalsMetricCard({required this.metricType, required this.patientId});

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
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
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
              return _buildEmptyStateCard(theme, 'Blood Pressure', Icons.favorite_outline, 'No readings logged yet.');
            }
            final latest = bpRecords.first;
            final systolic = latest.systolic!;
            final diastolic = latest.diastolic!;
            final isAbnormal = systolic >= 130 || systolic < 90 || diastolic >= 85 || diastolic < 60;
            final statusText = isAbnormal ? 'Abnormal' : 'Normal';
            final statusColor = isAbnormal ? theme.colorScheme.error : const Color(0xFF008A5E);

            final sparklinePoints = bpRecords
                .take(5)
                .map((r) => r.systolic!)
                .toList()
                .reversed
                .toList();

            return _buildMetricTile(
              context: context,
              title: 'Blood Pressure',
              value: '${systolic.toInt()}/${diastolic.toInt()}',
              unit: 'mmHg',
              statusText: statusText,
              statusColor: statusColor,
              icon: Icons.favorite_outline,
              iconColor: Colors.red,
              timeString: _formatDateTime(latest.dateTime),
              sparklinePoints: sparklinePoints,
            );
          } else {
            final glucoseRecords = records.where((r) => r.glucoseValue != null).toList();
            if (glucoseRecords.isEmpty) {
              return _buildEmptyStateCard(theme, 'Blood Glucose', Icons.opacity, 'No readings logged yet.');
            }
            final latest = glucoseRecords.first;
            final glucose = latest.glucoseValue!;
            final isAbnormal = glucose >= 140 || glucose < 70;
            final statusText = isAbnormal ? 'Abnormal' : 'Normal';
            final statusColor = isAbnormal ? theme.colorScheme.error : const Color(0xFF008A5E);
            final mealContext = latest.glucoseMealContext ?? 'Random';

            final displayGlucose = isMmol ? (glucose / 18.018) : glucose;
            final unitText = isMmol ? 'mmol/L' : 'mg/dL';
            final valueText = isMmol ? displayGlucose.toStringAsFixed(1) : '${glucose.toInt()}';

            final sparklinePoints = glucoseRecords
                .take(5)
                .map((r) => isMmol ? (r.glucoseValue! / 18.018) : r.glucoseValue!)
                .toList()
                .reversed
                .toList();

            return _buildMetricTile(
              context: context,
              title: 'Blood Glucose',
              value: valueText,
              unit: unitText,
              statusText: '$statusText (${mealContext[0].toUpperCase()}${mealContext.substring(1)})',
              statusColor: statusColor,
              icon: Icons.opacity,
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

  Widget _buildEmptyStateCard(ThemeData theme, String title, IconData icon, String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.06),
              radius: 24,
              child: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
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
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
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
                          color: iconColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
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
                            Text(
                              value,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                          painter: _SparklinePainter(
                            points: sparklinePoints,
                            lineColor: iconColor,
                          ),
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
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

// Sparkline trend indicator graph custom painter
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  _SparklinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final double minVal = points.reduce((a, b) => a < b ? a : b);
    final double maxVal = points.reduce((a, b) => a > b ? a : b);
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (points.length - 1);

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 10) + 5);
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets.first.dx, offsets.first.dy);
    fillPath.moveTo(offsets.first.dx, size.height);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (int i = 1; i < offsets.length; i++) {
      final prev = offsets[i - 1];
      final curr = offsets[i];
      
      final cp1 = Offset(prev.dx + stepX / 2, prev.dy);
      final cp2 = Offset(curr.dx - stepX / 2, curr.dy);
      
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.24), lineColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
