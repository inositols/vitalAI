import 'package:equatable/equatable.dart';
import '../../../../features/patients/data/models/patient_model.dart';

abstract class ConversationWorkflowEvent extends Equatable {
  const ConversationWorkflowEvent();

  @override
  List<Object?> get props => [];
}

/// User provided speech or text utterance.
class ConversationUtteranceSubmitted extends ConversationWorkflowEvent {
  final String utterance;
  final List<PatientModel> existingPatients;

  const ConversationUtteranceSubmitted(
    this.utterance, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [utterance, existingPatients];
}

/// User tapped an option or submitted an answer via interactive GenUI component.
class ConversationOptionSelected extends ConversationWorkflowEvent {
  final String field;
  final dynamic value;
  final List<PatientModel> existingPatients;

  const ConversationOptionSelected(
    this.field,
    this.value, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [field, value, existingPatients];
}

/// User explicitly selected a patient from disambiguation or search results.
class ConversationPatientSelected extends ConversationWorkflowEvent {
  final PatientModel patient;
  final List<PatientModel> existingPatients;

  const ConversationPatientSelected(
    this.patient, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [patient, existingPatients];
}

/// User corrected a previously entered field.
class ConversationFieldCorrected extends ConversationWorkflowEvent {
  final String field;
  final dynamic newValue;
  final List<PatientModel> existingPatients;

  const ConversationFieldCorrected(
    this.field,
    this.newValue, {
    this.existingPatients = const [],
  });

  @override
  List<Object?> get props => [field, newValue, existingPatients];
}

/// User confirmed consequential action (e.g. Save, Proceed).
class ConversationWorkflowConfirmed extends ConversationWorkflowEvent {
  const ConversationWorkflowConfirmed();
}

/// User cancelled active conversational workflow.
class ConversationWorkflowCancelled extends ConversationWorkflowEvent {
  const ConversationWorkflowCancelled();
}

/// User stepped back to previous workflow step.
class ConversationStepBackRequested extends ConversationWorkflowEvent {
  const ConversationStepBackRequested();
}

/// Reset conversation state back to idle.
class ConversationWorkflowReset extends ConversationWorkflowEvent {
  const ConversationWorkflowReset();
}
