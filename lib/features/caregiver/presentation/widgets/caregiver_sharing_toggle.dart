import 'package:flutter/material.dart';

class CaregiverSharingToggle extends StatelessWidget {
  final bool isSharingEnabled;
  final ValueChanged<bool> onChanged;

  const CaregiverSharingToggle({
    super.key,
    required this.isSharingEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SwitchListTile(
          title: const Text('Enable Remote Data Sharing'),
          subtitle: const Text('Allow caregivers to access logs'),
          value: isSharingEnabled,
          secondary: const Icon(Icons.share_outlined),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
