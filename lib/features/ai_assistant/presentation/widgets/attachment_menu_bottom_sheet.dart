import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/health_context.dart';

class AttachmentMenuBottomSheet extends StatelessWidget {
  final HealthContext? healthContext;
  final Function(String text) onSelectAttachment;

  const AttachmentMenuBottomSheet({
    super.key,
    this.healthContext,
    required this.onSelectAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    final bpSys = healthContext?.bpSystolicTrend.average?.round();
    final bpDia = healthContext?.bpDiastolicTrend.average?.round();
    final hasBp = healthContext != null && healthContext!.hasBpData && bpSys != null && bpDia != null;
    final bpSummary = hasBp
        ? 'Avg $bpSys/$bpDia mmHg (${healthContext!.bpSystolicTrend.direction})'
        : 'No blood pressure logs recorded yet';

    final glucoseAvg = healthContext?.glucoseTrend.average?.round();
    final hasGlucose = healthContext != null && healthContext!.hasGlucoseData && glucoseAvg != null;
    final glucoseSummary = hasGlucose
        ? 'Avg $glucoseAvg mg/dL (${healthContext!.glucoseTrend.direction})'
        : 'No glucose logs recorded yet';

    final hasRx = healthContext != null && healthContext!.hasMedications;
    final rxSummary = hasRx
        ? healthContext!.medications.take(3).join(', ')
        : 'No active medications registered';

    final pulseAvg = healthContext?.pulseTrend.average?.round();
    final spo2Avg = healthContext?.spo2Trend.average?.round();
    final hasPulseSpo2 = pulseAvg != null || spo2Avg != null;
    final pulseSpo2Summary = hasPulseSpo2
        ? 'Pulse: ${pulseAvg ?? '--'} bpm • SpO₂: ${spo2Avg != null ? '$spo2Avg%' : '--'}'
        : 'No pulse or SpO₂ readings logged';

    final totalLogs = healthContext?.totalVitalsCount ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.attachment_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Attach Clinical Context Snippet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select structured health data to embed into your AI consultation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // BP Tile
              _buildAttachmentTile(
                context: context,
                icon: Icons.favorite_rounded,
                color: AppColors.bpVital,
                title: 'Attach Blood Pressure Trend',
                subtitle: bpSummary,
                onTap: () => onSelectAttachment(
                  hasBp
                      ? 'Attached BP Log: $bpSummary. Can you evaluate this reading and suggest actionable adjustments?'
                      : 'I would like advice on tracking and managing my blood pressure.',
                ),
              ),

              // Glucose Tile
              _buildAttachmentTile(
                context: context,
                icon: Icons.water_drop_rounded,
                color: AppColors.glucoseVital,
                title: 'Attach Blood Glucose Log',
                subtitle: glucoseSummary,
                onTap: () => onSelectAttachment(
                  hasGlucose
                      ? 'Attached Glucose Log: $glucoseSummary. Is this within the ideal fasting/post-meal range?'
                      : 'I would like guidance on healthy blood glucose ranges and monitoring.',
                ),
              ),

              // Medication Tile
              _buildAttachmentTile(
                context: context,
                icon: Icons.medication_rounded,
                color: AppColors.tertiary,
                title: 'Attach Active Prescriptions',
                subtitle: rxSummary,
                onTap: () => onSelectAttachment(
                  hasRx
                      ? 'Attached Active Rx: $rxSummary. Are there specific side effects or timing precautions I should know?'
                      : 'Can you provide general guidelines on safe medication management and schedules?',
                ),
              ),

              // Pulse & SpO2 Tile
              _buildAttachmentTile(
                context: context,
                icon: Icons.monitor_heart_rounded,
                color: AppColors.spo2Vital,
                title: 'Attach Pulse & Oxygen Saturation',
                subtitle: pulseSpo2Summary,
                onTap: () => onSelectAttachment(
                  hasPulseSpo2
                      ? 'Attached Vitals: $pulseSpo2Summary. How do these cardiovascular indicators look?'
                      : 'What are normal resting heart rate and oxygen saturation (SpO₂) ranges?',
                ),
              ),

              // Full 30-day snapshot
              _buildAttachmentTile(
                context: context,
                icon: Icons.summarize_rounded,
                color: AppColors.secondary,
                title: 'Attach Full 30-Day Vitals Summary',
                subtitle: '$totalLogs total logs recorded',
                onTap: () => onSelectAttachment(
                  totalLogs > 0
                      ? 'Attached 30-Day Comprehensive Vitals Summary ($totalLogs readings). Please summarize my overall hemodynamic trajectory and doctor prep checklist.'
                      : 'Help me prepare a checklist of questions and vitals to discuss at my next doctor appointment.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
          onTap: onTap,
        ),
      ),
    );
  }
}
