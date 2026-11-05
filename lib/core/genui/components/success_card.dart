import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_component.dart';

/// Feedback card displayed strictly after repository confirmation of successful commit.
class SuccessCard extends StatelessWidget {
  final GenUiComponent component;
  final GenUiActionCallback? onActionSelected;

  const SuccessCard({
    super.key,
    required this.component,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final d = component.data;
    final message = component.title ?? d['message']?.toString() ?? 'Operation completed successfully.';
    final subtitle = component.subtitle ?? d['details']?.toString();
    final actions = component.actions;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((act) {
                return ElevatedButton(
                  onPressed: () => onActionSelected?.call(act),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  child: Text(act.label),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

