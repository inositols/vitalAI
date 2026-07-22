import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    final promptCards = [
      {
        'icon': Icons.analytics_outlined,
        'title': 'Analyze Vitals Trends',
        'subtitle': 'Review my blood pressure & glucose trends over the past 30 days',
        'prompt': 'Can you analyze my recent blood pressure and glucose trends and highlight any changes?',
        'color': Colors.blue,
      },
      {
        'icon': Icons.medication_outlined,
        'title': 'Medication Safety Check',
        'subtitle': 'Check my active prescriptions for potential side effects or timing',
        'prompt': 'Are there any specific side effects or timing precautions I should know for my active medications?',
        'color': Colors.purple,
      },
      {
        'icon': Icons.water_drop_outlined,
        'title': 'Explain Glucose Log',
        'subtitle': 'What do my latest fasting vs post-meal glucose numbers mean?',
        'prompt': 'What do my recent fasting glucose readings indicate about my blood sugar control?',
        'color': Colors.orange,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Doctor Visit Summary',
        'subtitle': 'Summarize key questions and health changes for my next clinic appointment',
        'prompt': 'Can you summarize my key health metrics and generate questions for my next doctor appointment?',
        'color': Colors.teal,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Gemini / ChatGPT Sparkle Hero Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${patientName.isNotEmpty ? patientName : 'there'} 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'How can I help with your health records today?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Suggested Action Prompts',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid of Prompt Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: promptCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (ctx, idx) {
              final card = promptCards[idx];
              final color = card['color'] as Color;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelectPrompt(card['prompt'] as String),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            card['icon'] as IconData,
                            color: color,
                            size: 20,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card['title'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card['subtitle'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
