import 'package:flutter/material.dart';

class CaregiverPermissionsCard extends StatelessWidget {
  final bool shareVitals;
  final bool shareInsights;
  final bool notifyOnCritical;
  final ValueChanged<bool> onShareVitalsChanged;
  final ValueChanged<bool> onShareInsightsChanged;
  final ValueChanged<bool> onNotifyOnCriticalChanged;

  const CaregiverPermissionsCard({
    super.key,
    required this.shareVitals,
    required this.shareInsights,
    required this.notifyOnCritical,
    required this.onShareVitalsChanged,
    required this.onShareInsightsChanged,
    required this.onNotifyOnCriticalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Share Vitals Logs'),
            subtitle: const Text('Includes blood pressure, glucose, SpO2, etc.'),
            value: shareVitals,
            onChanged: (val) => onShareVitalsChanged(val ?? false),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: const Text('Share AI Insights Summaries'),
            subtitle: const Text('Includes assistant summaries & alerts'),
            value: shareInsights,
            onChanged: (val) => onShareInsightsChanged(val ?? false),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: const Text('Critical Vitals Alert SMS/FCM'),
            subtitle: const Text('Sends alerts immediately for emergency readings'),
            value: notifyOnCritical,
            onChanged: (val) => onNotifyOnCriticalChanged(val ?? false),
          ),
        ],
      ),
    );
  }
}
