import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_component.dart';
import '../models/genui_option.dart';

/// Patient card and patient disambiguation list component.
class PatientCard extends StatelessWidget {
  final GenUiComponent component;
  final GenUiOptionCallback? onPatientSelected;

  const PatientCard({
    super.key,
    required this.component,
    this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final title = component.title ?? component.promptText ?? 'Select a patient:';
    final options = component.options;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              return _buildPatientListItem(context, option);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListItem(BuildContext context, GenUiOption option) {
    final meta = option.metadata;
    final age = meta['age'] ?? meta['patient']?['age'];
    final idStr = meta['id'] ?? meta['remoteId'] ?? meta['patient']?['remoteId'] ?? option.id;
    final gender = meta['gender'] ?? meta['patient']?['gender'];
    final condition = meta['condition'] ?? meta['primaryCondition'] ?? meta['patient']?['primaryCondition'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPatientSelected?.call(option),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withOpacity(0.1),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  option.label.isNotEmpty ? option.label[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'ID: $idStr',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        if (age != null)
                          Text(
                            '• Age: $age',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        if (gender != null)
                          Text(
                            '• $gender',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        if (condition != null)
                          Text(
                            '• $condition',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

