import 'package:flutter/material.dart';

class QuickActionCards extends StatelessWidget {
  final Function(String actionType) onTriggerAction;

  const QuickActionCards({
    super.key,
    required this.onTriggerAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      _ActionItem(
        id: 'health_summary',
        title: 'Health Summary',
        subtitle: 'Overview, positive changes & areas to monitor',
        icon: Icons.auto_awesome,
        color: Colors.indigo,
      ),
      _ActionItem(
        id: 'vital_analysis',
        title: 'Vital Analysis',
        subtitle: 'Detailed BP, Glucose, Pulse & SpO₂ analysis',
        icon: Icons.monitor_heart_outlined,
        color: Colors.teal,
      ),
      _ActionItem(
        id: 'doctor_prep',
        title: 'Doctor Preparation',
        subtitle: 'Trends, concerns & top questions to ask',
        icon: Icons.medical_services_outlined,
        color: Colors.deepOrange,
      ),
      _ActionItem(
        id: 'report_explanation',
        title: 'Report Explanation',
        subtitle: 'Explain recent vitals report in simple terms',
        icon: Icons.description_outlined,
        color: Colors.blueAccent,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'AI Health Actions',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (ctx, index) {
              final item = actions[index];
              return InkWell(
                onTap: () => onTriggerAction(item.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ActionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _ActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
