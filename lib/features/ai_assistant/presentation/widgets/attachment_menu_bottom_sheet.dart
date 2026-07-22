import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

class AttachmentMenuBottomSheet extends StatelessWidget {
  final Function(String text) onSelectAttachment;

  const AttachmentMenuBottomSheet({
    super.key,
    required this.onSelectAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Context Snippet',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.favorite, color: Colors.white, size: 20),
              ),
              title: const Text('Attach Blood Pressure Reading'),
              subtitle: const Text('Latest: 124/82 mmHg (Normal)'),
              onTap: () => onSelectAttachment(
                'Attached BP Log: 124/82 mmHg. Can you evaluate this reading?',
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.water_drop, color: Colors.white, size: 20),
              ),
              title: const Text('Attach Fasting Glucose Log'),
              subtitle: const Text('Latest: 105 mg/dL'),
              onTap: () => onSelectAttachment(
                'Attached Glucose Log: 105 mg/dL fasting. Is this within target range?',
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purpleAccent,
                child: Icon(Icons.medication, color: Colors.white, size: 20),
              ),
              title: const Text('Attach Active Prescription'),
              subtitle: const Text('Lisinopril 10mg daily'),
              onTap: () => onSelectAttachment(
                'Attached Rx: Lisinopril 10mg daily. Are there specific side effects to monitor?',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
