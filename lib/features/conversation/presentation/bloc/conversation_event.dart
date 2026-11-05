import 'package:equatable/equatable.dart';
import '../../domain/models/models.dart';
import '../../../patients/data/models/patient_model.dart';

/// Base class for all Conversation BLoC events.
abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted a text utterance to the conversational assistant.
class UserMessageSubmitted extends ConversationEvent {
  final String message;
  final List<PatientModel> existingPatients;

  const UserMessageSubmitted(
    this.message, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [message, existingPatients];
}

/// Spoken voice transcript captured and routed to the conversational assistant.
class VoiceTranscriptReceived extends ConversationEvent {
  final String transcript;
  final List<PatientModel> existingPatients;

  const VoiceTranscriptReceived(
    this.transcript, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [transcript, existingPatients];
}

/// GenUI interactive action selected by user (chip, card action, suggestion).
class GenUIActionSelected extends ConversationEvent {
  final GenUiAction action;
  final List<PatientModel> existingPatients;

  const GenUIActionSelected(
    this.action, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [action, existingPatients];
}

/// GenUI single-choice option selected by user.
class GenUIOptionSelected extends ConversationEvent {
  final GenUiOption option;
  final String? field;
  final List<PatientModel> existingPatients;

  const GenUIOptionSelected(
    this.option, {
    this.field,
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [option, field, existingPatients];
}

/// GenUI multiple-choice or batch selection submitted by user.
class GenUISelectionSubmitted extends ConversationEvent {
  final List<GenUiOption> selections;
  final String? field;
  final List<PatientModel> existingPatients;

  const GenUISelectionSubmitted(
    this.selections, {
    this.field,
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [selections, field, existingPatients];
}

/// Follow-up question answer submitted (via input field or chip).
class FollowUpAnswerSubmitted extends ConversationEvent {
  final String field;
  final dynamic answer;
  final List<PatientModel> existingPatients;

  const FollowUpAnswerSubmitted(
    this.field,
    this.answer, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [field, answer, existingPatients];
}

/// Legacy alias for ClarificationAnswerSubmitted.
typedef ClarificationAnswerSubmitted = FollowUpAnswerSubmitted;

/// Legacy alias for FollowUpOptionSelected.
class FollowUpOptionSelected extends ConversationEvent {
  final String field;
  final dynamic optionValue;
  final List<PatientModel> existingPatients;

  const FollowUpOptionSelected(
    this.field,
    this.optionValue, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [field, optionValue, existingPatients];
}

/// Request to undo or step back to the previous conversation workflow turn.
class WorkflowBackRequested extends ConversationEvent {
  const WorkflowBackRequested();
}

/// Request to explicitly abort and cancel the active conversational workflow.
class WorkflowCancelled extends ConversationEvent {
  const WorkflowCancelled();
}

/// Request to confirm and commit a consequential action (e.g. DB write, vitals record).
class WorkflowConfirmationRequested extends ConversationEvent {
  const WorkflowConfirmationRequested();
}

/// Request to retry the last failed action or step.
class ConversationRetryRequested extends ConversationEvent {
  final List<PatientModel> existingPatients;

  const ConversationRetryRequested({
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [existingPatients];
}

/// Reset conversation workflow state back to idle.
class ConversationResetRequested extends ConversationEvent {
  const ConversationResetRequested();
}
