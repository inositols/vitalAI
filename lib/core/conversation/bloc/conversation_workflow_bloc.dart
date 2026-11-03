import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/conversation_workflow_state.dart';
import '../services/conversation_orchestrator.dart';
import 'conversation_workflow_event.dart';

/// Conversation Workflow BLoC managing the state machine across all clinical intents.
class ConversationWorkflowBloc extends Bloc<ConversationWorkflowEvent, ConversationWorkflowState> {
  final ConversationOrchestrator orchestrator;

  ConversationWorkflowBloc({
    required this.orchestrator,
    ConversationWorkflowState? initialState,
  }) : super(initialState ?? ConversationWorkflowState.idle()) {
    on<ConversationUtteranceSubmitted>(_onUtteranceSubmitted);
    on<ConversationOptionSelected>(_onOptionSelected);
    on<ConversationPatientSelected>(_onPatientSelected);
    on<ConversationFieldCorrected>(_onFieldCorrected);
    on<ConversationWorkflowConfirmed>(_onWorkflowConfirmed);
    on<ConversationWorkflowCancelled>(_onWorkflowCancelled);
    on<ConversationStepBackRequested>(_onStepBackRequested);
    on<ConversationWorkflowReset>(_onWorkflowReset);
  }

  Future<void> _onUtteranceSubmitted(
    ConversationUtteranceSubmitted event,
    Emitter<ConversationWorkflowState> emit,
  ) async {
    final nextState = await orchestrator.handleUserUtterance(
      event.utterance,
      state,
      event.existingPatients,
    );
    emit(nextState);
  }

  Future<void> _onOptionSelected(
    ConversationOptionSelected event,
    Emitter<ConversationWorkflowState> emit,
  ) async {
    final nextState = await orchestrator.handleOptionSelection(
      event.field,
      event.value,
      state,
      event.existingPatients,
    );
    emit(nextState);
  }

  Future<void> _onPatientSelected(
    ConversationPatientSelected event,
    Emitter<ConversationWorkflowState> emit,
  ) async {
    final nextState = await orchestrator.handleOptionSelection(
      'patientId',
      event.patient.id,
      state,
      event.existingPatients,
    );
    emit(nextState.copyWith(activePatient: event.patient));
  }

  Future<void> _onFieldCorrected(
    ConversationFieldCorrected event,
    Emitter<ConversationWorkflowState> emit,
  ) async {
    final nextState = await orchestrator.handleOptionSelection(
      event.field,
      event.newValue,
      state,
      event.existingPatients,
    );
    emit(nextState);
  }

  Future<void> _onWorkflowConfirmed(
    ConversationWorkflowConfirmed event,
    Emitter<ConversationWorkflowState> emit,
  ) async {
    final nextState = await orchestrator.handleConfirmation(state);
    emit(nextState);
  }

  void _onWorkflowCancelled(
    ConversationWorkflowCancelled event,
    Emitter<ConversationWorkflowState> emit,
  ) {
    emit(orchestrator.handleCancel(state));
  }

  void _onStepBackRequested(
    ConversationStepBackRequested event,
    Emitter<ConversationWorkflowState> emit,
  ) {
    emit(orchestrator.handleStepBack(state));
  }

  void _onWorkflowReset(
    ConversationWorkflowReset event,
    Emitter<ConversationWorkflowState> emit,
  ) {
    emit(ConversationWorkflowState.idle());
  }
}
