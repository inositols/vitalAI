import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/genui_component_model.dart';
import '../../theme/design_tokens.dart';

class PatientProfileCardWidget extends StatelessWidget {
  final GenUiPatientProfileCardModel model;

  const PatientProfileCardWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(model.name.isNotEmpty ? model.name[0].toUpperCase() : 'P', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('${model.age} yrs • ${model.gender}', style: Theme.of(context).textTheme.bodySmall),
                if (model.primaryCondition != null)
                  Text('Condition: ${model.primaryCondition}', style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            onPressed: () => context.go('/patients'),
            tooltip: 'Switch Patient',
          ),
        ],
      ),
    );
  }
}
