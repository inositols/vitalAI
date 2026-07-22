import 'package:flutter/material.dart';
import '../../data/models/caregiver_model.dart';

class CaregiverListCard extends StatelessWidget {
  final List<CaregiverModel> caregivers;
  final ValueChanged<CaregiverModel> onDelete;

  const CaregiverListCard({
    super.key,
    required this.caregivers,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (caregivers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No connected caregivers yet. Invite a trusted caregiver below.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: caregivers.map((cg) {
          return ListTile(
            title: Text(cg.name),
            subtitle: Text(cg.email),
            leading: const CircleAvatar(child: Icon(Icons.person)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => onDelete(cg),
            ),
          );
        }).toList(),
      ),
    );
  }
}
