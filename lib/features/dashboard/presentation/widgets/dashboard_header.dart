import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/extensions/date_time_ext.dart';
import '../../../patients/data/models/patient_model.dart';

class DashboardHeader extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onSwitchPatient;

  const DashboardHeader({
    super.key,
    required this.patient,
    this.onSwitchPatient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onSwitchPatient,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: context.colorScheme.primary,
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
              style: TextStyle(
                color: context.colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateTimeExt.greeting}, ${patient.name}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Active Profile • Tap avatar to switch',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
