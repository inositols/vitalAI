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

/// User submitted an answer to an active clarification or missing field question.
class ClarificationAnswerSubmitted extends ConversationEvent {
  final String field;
  final dynamic answer;
  final List<PatientModel> existingPatients;

  const ClarificationAnswerSubmitted(
    this.field,
    this.answer, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [field, answer, existingPatients];
}

/// User selected a discrete option (e.g. chip, radio, patient card) from GenUI.
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
