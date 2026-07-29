import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';

class AiChatHeroHeader extends StatelessWidget {
  final String patientName;
  final Function(String prompt) onSelectPrompt;

  const AiChatHeroHeader({
    super.key,
    required this.patientName,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final promptCards = [
      {
        'icon': Icons.analytics_rounded,
        'title': 'Analyze Vitals Trends',
        'subtitle': 'Review blood pressure & glucose trends over past 30 days',
        'prompt': 'Can you analyze my recent blood pressure and glucose trends and highlight any changes?',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.medication_rounded,
        'title': 'Medication Timing',
        'subtitle': 'Check active prescriptions for optimal dosage advice',
        'prompt': 'Are there any specific side effects or timing precautions I should know for my active medications?',
        'color': AppColors.tertiary,
      },
      {
        'icon': Icons.water_drop_rounded,
        'title': 'Glucose Log Analysis',
        'subtitle': 'What do recent fasting vs post-meal numbers indicate?',
        'prompt': 'What do my recent fasting glucose readings indicate about my blood sugar control?',
        'color': AppColors.glucoseVital,
      },
      {
        'icon': Icons.description_rounded,
        'title': 'Doctor Visit Prep',
        'subtitle': 'Summarize key metrics and questions for clinic visit',
        'prompt': 'Can you summarize my key health metrics and generate questions for my next doctor appointment?',
        'color': AppColors.secondary,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          AppCard(
            gradient: AppColors.aiGradient,
            padding: const EdgeInsets.all(20),
            boxShadow: AppShadows.aiGlow(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${patientName.isNotEmpty ? patientName : 'there'} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'I am your AI Clinical Companion. How can I assist with your health insights today?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Suggested Consultations',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: promptCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (ctx, idx) {
              final card = promptCards[idx];
              final Color cardColor = card['color'] as Color;

              return AppCard(
                padding: const EdgeInsets.all(14),
                borderRadius: AppRadius.xl,
                onTap: () => onSelectPrompt(card['prompt'] as String),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        card['icon'] as IconData,
                        color: cardColor,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      card['title'] as String,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card['subtitle'] as String,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
