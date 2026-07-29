import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
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
    final isDark = context.isDarkMode;

    if (caregivers.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              'No Connected Caregivers',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Invite family members or clinical guardians to monitor logs remotely.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: caregivers.map((cg) {
          return ListTile(
            title: Text(cg.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(cg.email, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                cg.name.isNotEmpty ? cg.name[0].toUpperCase() : 'C',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              tooltip: 'Revoke access',
              onPressed: () => onDelete(cg),
            ),
          );
        }).toList(),
      ),
    );
  }
}
