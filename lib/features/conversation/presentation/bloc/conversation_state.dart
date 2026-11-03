import 'package:equatable/equatable.dart';
import '../../domain/models/models.dart';

/// Base abstract class for Conversation BLoC states.
/// Every state wraps the strongly-typed [ConversationWorkflowState] maintaining
/// the full conversational context (active patient, collected parameters,
/// validation errors, history stack, and active question).
abstract class ConversationState extends Equatable {
  final ConversationWorkflowState workflowState;

  const ConversationState({required this.workflowState});

  @override
  List<Object?> get props => [workflowState];
}

/// Initial idle state when no conversation is active.
class ConversationInitial extends ConversationState {
  ConversationInitial({ConversationWorkflowState? workflowState})
      : super(workflowState: workflowState ?? ConversationWorkflowState.idle());
}

/// State when natural language utterance or selection is being parsed/validated.
class ConversationProcessing extends ConversationState {
  const ConversationProcessing({required super.workflowState});
}

/// State when user input is needed for a missing required field or open clarification.
class ConversationAwaitingInput extends ConversationState {
  final FollowUpQuestion question;

  const ConversationAwaitingInput({
    required super.workflowState,
    required this.question,
  });

  @override
  List<Object?> get props => [workflowState, question];
}

/// State when multiple discrete choices or candidate entities need user selection.
class ConversationAwaitingSelection extends ConversationState {
  final FollowUpQuestion question;
  final List<FollowUpOption> options;

  const ConversationAwaitingSelection({
    required super.workflowState,
    required this.question,
    this.options = const [],
  });

  @override
  List<Object?> get props => [workflowState, question, options];
}

/// State when all required parameters are collected and confirmation is needed
/// before committing a consequential clinical write.
class ConversationAwaitingConfirmation extends ConversationState {
  final FollowUpQuestion confirmationQuestion;

  const ConversationAwaitingConfirmation({
    required super.workflowState,
    required this.confirmationQuestion,
  });

  @override
  List<Object?> get props => [workflowState, confirmationQuestion];
}

/// State when an authorized database write, sync, or backend action is in progress.
class ConversationExecutingAction extends ConversationState {
  const ConversationExecutingAction({required super.workflowState});
}

/// State when a clinical action has successfully completed.
class ConversationSuccess extends ConversationState {
  final dynamic result;
  final String successMessage;

  const ConversationSuccess({
    required super.workflowState,
    this.result,
    this.successMessage = 'Action completed successfully.',
  });

  @override
  List<Object?> get props => [workflowState, result, successMessage];
}

/// State when an error or validation failure occurred during conversation workflow.
class ConversationFailure extends ConversationState {
  final String errorMessage;

  const ConversationFailure({
    required super.workflowState,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [workflowState, errorMessage];
}
