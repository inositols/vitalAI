import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/models.dart';
import '../../domain/use_cases/process_user_message_use_case.dart';
import '../../domain/use_cases/submit_clarification_use_case.dart';
import '../../domain/use_cases/workflow_control_use_cases.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

/// BLoC coordinating the universal conversational workflow and adaptive GenUI.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ProcessUserMessageUseCase processUserMessage;
  final SubmitClarificationUseCase submitClarification;
  final ConfirmConversationWorkflowUseCase confirmWorkflow;
  final CancelConversationWorkflowUseCase cancelWorkflow;
  final StepBackConversationWorkflowUseCase stepBackWorkflow;

  ConversationBloc({
    required this.processUserMessage,
    required this.submitClarification,
    required this.confirmWorkflow,
    required this.cancelWorkflow,
    required this.stepBackWorkflow,
    ConversationWorkflowState? initialState,
  }) : super(ConversationInitial(workflowState: initialState)) {
    on<UserMessageSubmitted>(_onUserMessageSubmitted);
    on<VoiceTranscriptReceived>(_onVoiceTranscriptReceived);
    on<ClarificationAnswerSubmitted>(_onClarificationAnswerSubmitted);
    on<FollowUpOptionSelected>(_onFollowUpOptionSelected);
    on<WorkflowBackRequested>(_onWorkflowBackRequested);
    on<WorkflowCancelled>(_onWorkflowCancelled);
    on<WorkflowConfirmationRequested>(_onWorkflowConfirmationRequested);
    on<ConversationRetryRequested>(_onConversationRetryRequested);
    on<ConversationResetRequested>(_onConversationResetRequested);
  }

  Future<void> _onUserMessageSubmitted(
    UserMessageSubmitted event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationProcessing(workflowState: state.workflowState));
    try {
      final nextWorkflow = await processUserMessage(
        message: event.message,
        currentState: state.workflowState,
        existingPatients: event.existingPatients,
      );
      emit(_mapWorkflowToState(nextWorkflow));
    } catch (e) {
      emit(ConversationFailure(
        workflowState: state.workflowState,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onVoiceTranscriptReceived(
    VoiceTranscriptReceived event,
    Emitter<ConversationState> emit,
  ) async {
    add(UserMessageSubmitted(
      event.transcript,
      existingPatients: event.existingPatients,
    ));
  }

  Future<void> _onClarificationAnswerSubmitted(
    ClarificationAnswerSubmitted event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationProcessing(workflowState: state.workflowState));
    try {
      final nextWorkflow = await submitClarification(
        field: event.field,
        value: event.answer,
        currentState: state.workflowState,
        existingPatients: event.existingPatients,
      );
      emit(_mapWorkflowToState(nextWorkflow));
    } catch (e) {
      emit(ConversationFailure(
        workflowState: state.workflowState,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFollowUpOptionSelected(
    FollowUpOptionSelected event,
    Emitter<ConversationState> emit,
  ) async {
    add(ClarificationAnswerSubmitted(
      event.field,
      event.optionValue,
      existingPatients: event.existingPatients,
    ));
  }

  void _onWorkflowBackRequested(
    WorkflowBackRequested event,
    Emitter<ConversationState> emit,
  ) {
    final nextWorkflow = stepBackWorkflow(state.workflowState);
    emit(_mapWorkflowToState(nextWorkflow));
  }

  void _onWorkflowCancelled(
    WorkflowCancelled event,
    Emitter<ConversationState> emit,
  ) {
    final nextWorkflow = cancelWorkflow(state.workflowState);
    emit(_mapWorkflowToState(nextWorkflow));
  }

  Future<void> _onWorkflowConfirmationRequested(
    WorkflowConfirmationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationExecutingAction(
      workflowState: state.workflowState.copyWith(status: WorkflowStatus.executingAction),
    ));
    try {
      final nextWorkflow = await confirmWorkflow(state.workflowState);
      emit(_mapWorkflowToState(nextWorkflow));
    } catch (e) {
      emit(ConversationFailure(
        workflowState: state.workflowState,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onConversationRetryRequested(
    ConversationRetryRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (state.workflowState.status == WorkflowStatus.failed) {
      add(const WorkflowConfirmationRequested());
    }
  }

  void _onConversationResetRequested(
    ConversationResetRequested event,
    Emitter<ConversationState> emit,
  ) {
    emit(ConversationInitial());
  }

  ConversationState _mapWorkflowToState(ConversationWorkflowState wf) {
    switch (wf.status) {
      case WorkflowStatus.idle:
      case WorkflowStatus.cancelled:
        return ConversationInitial(workflowState: wf);

      case WorkflowStatus.interpretingRequest:
      case WorkflowStatus.validating:
        return ConversationProcessing(workflowState: wf);

      case WorkflowStatus.awaitingSelection:
        return ConversationAwaitingSelection(
          workflowState: wf,
          question: wf.currentQuestion ??
              const FollowUpQuestion(
                targetField: 'selection',
                promptText: 'Please select an option',
                questionType: GenUiQuestionType.singleChoice,
              ),
          options: wf.availableOptions,
        );

      case WorkflowStatus.awaitingClarification:
      case WorkflowStatus.collectingInformation:
        return ConversationAwaitingInput(
          workflowState: wf,
          question: wf.currentQuestion ??
              const FollowUpQuestion(
                targetField: 'input',
                promptText: 'Please provide more details',
                questionType: GenUiQuestionType.openText,
              ),
        );

      case WorkflowStatus.awaitingConfirmation:
        return ConversationAwaitingConfirmation(
          workflowState: wf,
          confirmationQuestion: wf.currentQuestion ??
              const FollowUpQuestion(
                targetField: 'confirmation',
                promptText: 'Please confirm details',
                questionType: GenUiQuestionType.confirmationCard,
              ),
        );

      case WorkflowStatus.executingAction:
        return ConversationExecutingAction(workflowState: wf);

      case WorkflowStatus.completed:
        return ConversationSuccess(
          workflowState: wf,
          result: wf.executionResult,
          successMessage: 'Clinical workflow completed successfully.',
        );

      case WorkflowStatus.failed:
        return ConversationFailure(
          workflowState: wf,
          errorMessage: wf.errorMessage ?? 'An error occurred during conversational execution.',
        );
    }
  }
}
