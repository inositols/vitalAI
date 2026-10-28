import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';

/// Previews a simulated VitalAI Flutter GenUI HealthCard from model-generated JSON.
class GenUiCardPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> json;

  const GenUiCardPreviewWidget({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final schema = json['\$schema'] as String? ?? 'vitalai:genui:vitals_card';

    // Metric details
    final metric = json['metric'] is Map ? json['metric'] as Map<String, dynamic> : null;
    final primaryVal = metric?['primaryValue']?.toString() ?? '—';
    final unit = metric?['unit']?.toString() ?? '';
    final contextStr = metric?['context']?.toString() ?? '';

    // Clinical classification
    final classification = json['clinicalClassification'] is Map
        ? json['clinicalClassification'] as Map<String, dynamic>
        : null;
    final urgencyRaw = (classification?['urgencyLevel']?.toString() ?? 'moderate').toLowerCase();

    Color urgencyColor;
    if (urgencyRaw.contains('emerg') || urgencyRaw.contains('crit')) {
      urgencyColor = AppColors.error;
    } else if (urgencyRaw.contains('high') || urgencyRaw.contains('elev')) {
      urgencyColor = AppColors.glucoseVital;
    } else {
      urgencyColor = AppColors.secondary;
    }

    final summary = json['summary']?.toString() ?? 'No clinical summary generated.';
    final guidance = (json['actionableGuidance'] is List)
        ? (json['actionableGuidance'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final doctorPoints = (json['doctorDiscussionPoints'] is List)
        ? (json['doctorDiscussionPoints'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final disclaimer = json['safetyDisclaimer']?.toString() ??
        'VitalAI is an experimental health aid, not a diagnostic system.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  schema,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: urgencyColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  classification?['urgencyLevel']?.toString() ?? 'Elevated Urgency',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Metric Hero
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  primaryVal,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: urgencyColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                if (contextStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      contextStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Summary Section
          Text(
            summary,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),

          // Actionable Guidance
          if (guidance.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'ACTIONABLE GUIDANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            ...guidance.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👉 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Discussion Points for Doctor
          if (doctorPoints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'DOCTOR DISCUSSION POINTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            ...doctorPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Safety Disclaimer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glucoseVital.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glucoseVital.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.glucoseVital, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
