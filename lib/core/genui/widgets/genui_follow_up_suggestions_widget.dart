import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../../features/ai_assistant/presentation/bloc/ai_assistant_state.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';

/// Dynamic interactive GenUI follow-up suggestions widget displaying contextual chips and cards.
class GenUiFollowUpSuggestionsWidget extends StatefulWidget {
  final GenUiComponentModel model;

  const GenUiFollowUpSuggestionsWidget({
    super.key,
    required this.model,
  });

  @override
  State<GenUiFollowUpSuggestionsWidget> createState() => _GenUiFollowUpSuggestionsWidgetState();
}

class _GenUiFollowUpSuggestionsWidgetState extends State<GenUiFollowUpSuggestionsWidget> {
  int? _tappedIndex;
  bool _isProcessing = false;

  List<GenUiFollowUpAction> get _actions {
    if (widget.model is GenUiFollowUpSuggestionsModel) {
      return (widget.model as GenUiFollowUpSuggestionsModel).suggestions;
    }
    if (widget.model is GenUiFollowUpActionModel) {
      return [(widget.model as GenUiFollowUpActionModel).action];
    }
    return [];
  }

  String get _title {
    if (widget.model is GenUiFollowUpSuggestionsModel) {
      final t = (widget.model as GenUiFollowUpSuggestionsModel).title;
      if (t != null && t.trim().isNotEmpty) return t.trim();
    }
    return 'Suggested Follow-ups & Actions';
  }

  Future<void> _onActionTapped(BuildContext context, int index, GenUiFollowUpAction action) async {
    final aiState = context.read<AiAssistantBloc>().state;
    final isGenerating = aiState is AiAssistantLoaded && aiState.isGenerating;

    if (isGenerating || _isProcessing) {
      return; // Prevent duplicate submissions while generation is pending
    }

    setState(() {
      _tappedIndex = index;
      _isProcessing = true;
    });

    try {
      await GenUiActionHandler.handleFollowUpAction(context, action);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  IconData _iconForAction(GenUiFollowUpAction action) {
    switch (action.actionType) {
      case GenUiActionType.followUpQuestion:
        return Icons.chat_bubble_outline_rounded;
      case GenUiActionType.navigation:
        return Icons.open_in_new_rounded;
      case GenUiActionType.dataAction:
        return Icons.insights_rounded;
      case GenUiActionType.informationExpansion:
        return Icons.manage_search_rounded;
      case GenUiActionType.unknown:
        return Icons.arrow_forward_rounded;
    }
  }

  Color _colorForAction(GenUiFollowUpAction action, bool isDark) {
    switch (action.actionType) {
      case GenUiActionType.followUpQuestion:
        return AppColors.primary;
      case GenUiActionType.navigation:
        return AppColors.secondary;
      case GenUiActionType.dataAction:
        return AppColors.success;
      case GenUiActionType.informationExpansion:
        return AppColors.warning;
      case GenUiActionType.unknown:
        return isDark ? Colors.white70 : const Color(0xFF334155);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AiAssistantBloc, AiAssistantState>(
      builder: (context, aiState) {
        final isGenerating = aiState is AiAssistantLoaded && aiState.isGenerating;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard.withValues(alpha: 0.8) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  if (isGenerating || _isProcessing) ...[
                    const Spacer(),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Action Cards / Chips List
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(actions.length, (index) {
                  final action = actions[index];
                  final isTapped = _tappedIndex == index;
                  final actionColor = _colorForAction(action, isDark);
                  final isDisabled = isGenerating || _isProcessing;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isDisabled ? null : () => _onActionTapped(context, index, action),
                      borderRadius: BorderRadius.circular(20),
                      splashColor: actionColor.withValues(alpha: 0.2),
                      highlightColor: actionColor.withValues(alpha: 0.1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isTapped
                              ? actionColor.withValues(alpha: 0.2)
                              : isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isTapped
                                ? actionColor
                                : actionColor.withValues(alpha: isDark ? 0.35 : 0.45),
                            width: isTapped ? 1.5 : 1.0,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconForAction(action),
                              size: 15,
                              color: isDisabled ? Colors.grey : actionColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled
                                      ? (isDark ? Colors.white38 : Colors.black38)
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isDisabled ? Colors.transparent : actionColor.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
