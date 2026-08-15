import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_card.dart';

class AiChatHeroHeader extends StatefulWidget {
  final String patientName;
  final Function(String prompt) onSelectPrompt;

  const AiChatHeroHeader({
    super.key,
    required this.patientName,
    required this.onSelectPrompt,
  });

  @override
  State<AiChatHeroHeader> createState() => _AiChatHeroHeaderState();
}

class _AiChatHeroHeaderState extends State<AiChatHeroHeader> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Vitals',
    'Medications',
    'Lifestyle',
    'Doctor Prep',
  ];

  final List<Map<String, dynamic>> _allPrompts = const [
    {
      'category': 'Vitals',
      'icon': Icons.analytics_rounded,
      'title': 'Analyze Vitals Trends',
      'subtitle': 'Review blood pressure & glucose trends over past 30 days',
      'prompt': 'Can you analyze my recent blood pressure and glucose trends and highlight any changes?',
      'color': AppColors.primary,
      'tag': 'Trends',
    },
    {
      'category': 'Medications',
      'icon': Icons.medication_rounded,
      'title': 'Medication Timing',
      'subtitle': 'Check active prescriptions for optimal dosage advice',
      'prompt': 'Are there any specific side effects or timing precautions I should know for my active medications?',
      'color': AppColors.tertiary,
      'tag': 'Dosage',
    },
    {
      'category': 'Vitals',
      'icon': Icons.water_drop_rounded,
      'title': 'Glucose Log Analysis',
      'subtitle': 'What do recent fasting vs post-meal numbers indicate?',
      'prompt': 'What do my recent fasting glucose readings indicate about my blood sugar control?',
      'color': AppColors.glucoseVital,
      'tag': 'Glucose',
    },
    {
      'category': 'Doctor Prep',
      'icon': Icons.description_rounded,
      'title': 'Doctor Visit Prep',
      'subtitle': 'Summarize key metrics and questions for clinic visit',
      'prompt': 'Can you summarize my key health metrics and generate questions for my next doctor appointment?',
      'color': AppColors.secondary,
      'tag': 'Checkup',
    },
    {
      'category': 'Lifestyle',
      'icon': Icons.favorite_border_rounded,
      'title': 'Blood Pressure Optimization',
      'subtitle': 'Actionable dietary & DASH plan guidance for lower BP',
      'prompt': 'How can I lower my blood pressure through dietary changes and daily habits?',
      'color': AppColors.bpVital,
      'tag': 'Diet',
    },
    {
      'category': 'Lifestyle',
      'icon': Icons.nightlight_round,
      'title': 'Stress & Heart Rate',
      'subtitle': 'Understand how daily stress influences pulse and BP',
      'prompt': 'How does stress and sleep quality affect my heart rate and blood pressure?',
      'color': AppColors.pulseVital,
      'tag': 'Wellness',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final displayName = widget.patientName.isNotEmpty ? widget.patientName : 'there';

    final filteredPrompts = _selectedCategory == 'All'
        ? _allPrompts
        : _allPrompts.where((p) => p['category'] == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero AI Banner Card
          AppCard(
            gradient: AppColors.aiGradient,
            padding: const EdgeInsets.all(20),
            boxShadow: AppShadows.aiGlow,
            borderRadius: AppRadius.xxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const AppBrandLogo(
                        size: 42,
                        iconSize: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $displayName 👋',
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
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Snapshot feature pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Context Active • Connected to Clinical Vitals Engine',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Category Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: context.colorScheme.primaryContainer,
                    checkmarkColor: context.colorScheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? context.colorScheme.primary
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? context.colorScheme.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Suggested Consultation Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPrompts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (ctx, idx) {
              final card = filteredPrompts[idx];
              final Color cardColor = card['color'] as Color;

              return AppCard(
                padding: const EdgeInsets.all(12),
                borderRadius: AppRadius.lg,
                onTap: () => widget.onSelectPrompt(card['prompt'] as String),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            card['icon'] as IconData,
                            color: cardColor,
                            size: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkContainer : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            card['tag'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      card['title'] as String,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      card['subtitle'] as String,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 10,
                        height: 1.25,
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
