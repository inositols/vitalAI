import 'package:flutter/material.dart';

class InviteCaregiverCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendInvite;

  const InviteCaregiverCard({
    super.key,
    required this.controller,
    required this.onSendInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Caregiver Email Address',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSendInvite,
              child: const Text('Send Invitation Link'),
            ),
          ],
        ),
      ),
    );
  }
}
