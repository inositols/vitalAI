import 'package:flutter/material.dart';
import '../models/conversation_workflow_state.dart';
import '../models/follow_up_question.dart';
import '../models/genui_question_type.dart';
import '../widgets/adaptive_genui_follow_up_card.dart';

typedef GenUiFollowUpBuilder = Widget Function(
  BuildContext context,
  FollowUpQuestion question,
  ConversationWorkflowState state,
  ValueChanged<dynamic> onAnswer,
  VoidCallback onConfirm,
  VoidCallback onCancel,
  VoidCallback onSkip,
  VoidCallback onBack,
);

/// Registry associating GenUiQuestionTypes with approved, validated Flutter UI builders.
class GenUiComponentRegistry {
  static final GenUiComponentRegistry _instance = GenUiComponentRegistry._internal();
  factory GenUiComponentRegistry() => _instance;
  GenUiComponentRegistry._internal();

  final Map<GenUiQuestionType, GenUiFollowUpBuilder> _customBuilders = {};

  /// Register custom builder for a GenUiQuestionType.
  void register(GenUiQuestionType type, GenUiFollowUpBuilder builder) {
    _customBuilders[type] = builder;
  }

  /// Builds the approved UI component for a follow-up question.
  Widget buildComponent({
    required BuildContext context,
    required FollowUpQuestion question,
    required ConversationWorkflowState state,
    required ValueChanged<dynamic> onAnswer,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required VoidCallback onSkip,
    required VoidCallback onBack,
  }) {
    final custom = _customBuilders[question.questionType];
    if (custom != null) {
      return custom(context, question, state, onAnswer, onConfirm, onCancel, onSkip, onBack);
    }

    return AdaptiveGenUiFollowUpCard(
      question: question,
      state: state,
      onAnswer: onAnswer,
      onConfirm: onConfirm,
      onCancel: onCancel,
      onSkip: onSkip,
      onBack: onBack,
    );
  }
}
