import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';

/// Renders contextual suggested action chips/cards naturally below AI responses.
class SuggestionCard extends StatelessWidget {
  final GenUiComponent component;
  final List<GenUiAction>? overrideActions;
  final GenUiActionCallback? onActionSelected;

  const SuggestionCard({
    super.key,
    required this.component,
    this.overrideActions,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final actions = overrideActions ?? component.actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    final title = component.title ?? 'Suggested next actions';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return _buildActionChip(context, action);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, GenUiAction action) {
    final icon = _resolveIcon(action);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onActionSelected?.call(action),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withOpacity(0.12),
        highlightColor: AppColors.primary.withOpacity(0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(GenUiAction action) {
    switch (action.type) {
      case GenUiActionType.compareVitals:
        return Icons.compare_arrows_rounded;
      case GenUiActionType.viewVitalHistory:
        return Icons.history_rounded;
      case GenUiActionType.generateSummary:
        return Icons.summarize_rounded;
      case GenUiActionType.recordVitals:
        return Icons.add_circle_outline_rounded;
      case GenUiActionType.viewPatient:
        return Icons.person_search_rounded;
      case GenUiActionType.editPatient:
        return Icons.edit_note_rounded;
      case GenUiActionType.confirmSave:
        return Icons.check_circle_rounded;
      case GenUiActionType.cancelWorkflow:
        return Icons.cancel_outlined;
      case GenUiActionType.addInformation:
        return Icons.post_add_rounded;
      case GenUiActionType.changeDateRange:
        return Icons.date_range_rounded;
      case GenUiActionType.viewIndividualReadings:
        return Icons.table_rows_rounded;
      case GenUiActionType.viewTrends:
        return Icons.trending_up_rounded;
      case GenUiActionType.askQuestion:
        return Icons.chat_bubble_outline_rounded;
      case GenUiActionType.skipField:
        return Icons.skip_next_rounded;
      case GenUiActionType.custom:
        return Icons.touch_app_rounded;
    }
  }
}

