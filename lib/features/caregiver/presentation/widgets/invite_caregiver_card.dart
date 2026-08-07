import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

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
    return AppCard(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Caregiver Email Address',
              hintText: 'caregiver@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Send Access Invitation',
            onPressed: onSendInvite,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }
}
