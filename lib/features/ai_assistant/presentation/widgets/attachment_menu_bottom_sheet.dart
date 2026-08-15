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
    final bpSummary = (healthContext != null && healthContext!.hasBpData && bpSys != null && bpDia != null)
        ? 'Avg $bpSys/$bpDia mmHg (${healthContext!.bpSystolicTrend.direction})'
        : 'Latest: 124/82 mmHg (Normal)';

    final glucoseAvg = healthContext?.glucoseTrend.average?.round();
    final glucoseSummary = (healthContext != null && healthContext!.hasGlucoseData && glucoseAvg != null)
        ? 'Avg $glucoseAvg mg/dL (${healthContext!.glucoseTrend.direction})'
        : 'Latest: 98 mg/dL fasting';

    final rxSummary = healthContext != null && healthContext!.hasMedications
        ? healthContext!.medications.take(2).join(', ')
        : 'Lisinopril 10mg daily';

    final pulseAvg = healthContext?.pulseTrend.average?.round() ?? 72;
    final spo2Avg = healthContext?.spo2Trend.average?.round() ?? 98;
    final pulseSpo2Summary = 'Pulse: $pulseAvg bpm • SpO₂: $spo2Avg%';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
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
                  'Attached BP Log: $bpSummary. Can you evaluate this reading and suggest actionable adjustments?',
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
                  'Attached Glucose Log: $glucoseSummary. Is this within the ideal fasting/post-meal range?',
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
                  'Attached Active Rx: $rxSummary. Are there specific side effects or timing precautions I should know?',
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
                  'Attached Vitals: $pulseSpo2Summary. How do these cardiovascular indicators look?',
                ),
              ),

              // Full 30-day snapshot
              _buildAttachmentTile(
                context: context,
                icon: Icons.summarize_rounded,
                color: AppColors.secondary,
                title: 'Attach Full 30-Day Vitals Summary',
                subtitle: '${healthContext?.totalVitalsCount ?? 12} total logs analyzed',
                onTap: () => onSelectAttachment(
                  'Attached 30-Day Comprehensive Vitals Summary. Please summarize my overall hemodynamic trajectory and doctor prep checklist.',
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
