import 'package:equatable/equatable.dart';
import 'genui_question_type.dart';

/// Single parameter-gathering or decision step in a conversational workflow.
class WorkflowStep extends Equatable {
  final String key;
  final String label;
  final String questionPrompt;
  final GenUiQuestionType uiType;
  final bool isRequired;
  final String? helpText;
  final String? unit;

  const WorkflowStep({
    required this.key,
    required this.label,
    required this.questionPrompt,
    required this.uiType,
    this.isRequired = true,
    this.helpText,
    this.unit,
  });

  @override
  List<Object?> get props => [key, label, questionPrompt, uiType, isRequired, helpText, unit];
}
