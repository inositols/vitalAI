import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/conversation/models/genui_question_type.dart';
import '../../domain/models/models.dart';
import '../../domain/use_cases/process_user_message_use_case.dart';
import '../../domain/use_cases/submit_clarification_use_case.dart';
import '../../domain/use_cases/workflow_control_use_cases.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

/// Central BLoC coordinating the universal conversational workflow and adaptive GenUI.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ProcessUserMessageUseCase processUserMessage;
  final SubmitClarificationUseCase submitClarification;
  final ConfirmConversationWorkflowUseCase confirmWorkflow;
  final CancelConversationWorkflowUseCase cancelWorkflow;
  final StepBackConversationWorkflowUseCase stepBackWorkflow;
  final GenUiEngine genUiEngine;
  final SuggestionService suggestionService;
  final ComponentSelectionService componentSelectionService;

  ConversationBloc({
    required this.processUserMessage,
    required this.submitClarification,
    required this.confirmWorkflow,
    required this.cancelWorkflow,
    required this.stepBackWorkflow,
    this.genUiEngine = const GenUiEngine(),
    this.suggestionService = const SuggestionService(),
    this.componentSelectionService = const ComponentSelectionService(),
    ConversationWorkflowState? initialState,
  }) : super(ConversationInitial(workflowState: initialState)) {
    on<UserMessageSubmitted>(_onUserMessageSubmitted);
    on<VoiceTranscriptReceived>(_onVoiceTranscriptReceived);
    on<GenUIActionSelected>(_onGenUiActionSelected);
    on<GenUIOptionSelected>(_onGenUiOptionSelected);
    on<GenUISelectionSubmitted>(_onGenUiSelectionSubmitted);
    on<FollowUpAnswerSubmitted>(_onFollowUpAnswerSubmitted);
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

  Future<void> _onGenUiActionSelected(
    GenUIActionSelected event,
    Emitter<ConversationState> emit,
  ) async {
    final action = event.action;

    switch (action.type) {
      case GenUiActionType.cancelWorkflow:
        add(const WorkflowCancelled());
        break;

      case GenUiActionType.confirmSave:
        add(const WorkflowConfirmationRequested());
        break;

      case GenUiActionType.skipField:
        final currentField = state.workflowState.currentQuestion?.targetField ?? 'optional';
        add(FollowUpAnswerSubmitted(
          currentField,
          'skip',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.compareVitals:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Compare $name vital signs' : 'Compare previous vital readings',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.viewVitalHistory:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Show $name vital history' : 'Show complete vital history',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.generateSummary:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Summarise $name patient history' : 'Generate patient clinical summary',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.recordVitals:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Record new vitals for $name' : 'Record new vitals',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.viewPatient:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Open patient profile for $name' : 'View patient details',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.editPatient:
        final name = action.payload['patientName'] ?? state.workflowState.activePatient?.name ?? '';
        add(UserMessageSubmitted(
          name.isNotEmpty ? 'Edit patient details for $name' : 'Edit patient information',
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.addInformation:
        add(FollowUpAnswerSubmitted(
          'additional_info',
          action.payload['info'] ?? action.label,
          existingPatients: event.existingPatients,
        ));
        break;

      case GenUiActionType.changeDateRange:
        final range = action.payload['range']?.toString() ?? '7D';
        add(UserMessageSubmitted(
          'Show vitals for range $range',
          existingPatients: event.existingPatients,
        ));
        break;

      default:
        add(UserMessageSubmitted(
          action.label,
          existingPatients: event.existingPatients,
        ));
        break;
    }
  }

  Future<void> _onGenUiOptionSelected(
    GenUIOptionSelected event,
    Emitter<ConversationState> emit,
  ) async {
    final targetField = event.field ?? state.workflowState.currentQuestion?.targetField ?? 'selection';
    add(FollowUpAnswerSubmitted(
      targetField,
      event.option.value,
      existingPatients: event.existingPatients,
    ));
  }

  Future<void> _onGenUiSelectionSubmitted(
    GenUISelectionSubmitted event,
    Emitter<ConversationState> emit,
  ) async {
    final targetField = event.field ?? state.workflowState.currentQuestion?.targetField ?? 'multi_selection';
    final values = event.selections.map((s) => s.value).toList();
    add(FollowUpAnswerSubmitted(
      targetField,
      values,
      existingPatients: event.existingPatients,
    ));
  }

  Future<void> _onFollowUpAnswerSubmitted(
    FollowUpAnswerSubmitted event,
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
    add(FollowUpAnswerSubmitted(
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
    final genUi = _buildGenUiResponseForWorkflow(wf);

    switch (wf.status) {
      case WorkflowStatus.idle:
      case WorkflowStatus.cancelled:
        return ConversationInitial(workflowState: wf, genUiResponse: genUi);

      case WorkflowStatus.interpretingRequest:
      case WorkflowStatus.validating:
        return ConversationProcessing(workflowState: wf, genUiResponse: genUi);

      case WorkflowStatus.awaitingSelection:
        return ConversationAwaitingSelection(
          workflowState: wf,
          question: wf.currentQuestion ??
              const FollowUpQuestion(
                id: 'selection_fallback',
                targetField: 'selection',
                promptText: 'Please select an option',
                questionType: GenUiQuestionType.singleChoice,
              ),
          options: wf.availableOptions,
          genUiResponse: genUi,
        );

      case WorkflowStatus.awaitingClarification:
      case WorkflowStatus.collectingInformation:
        return ConversationAwaitingInput(
          workflowState: wf,
          question: wf.currentQuestion ??
              const FollowUpQuestion(
                id: 'input_fallback',
                targetField: 'input',
                promptText: 'Please provide more details',
                questionType: GenUiQuestionType.textInput,
              ),
          genUiResponse: genUi,
        );

      case WorkflowStatus.awaitingConfirmation:
        return ConversationAwaitingConfirmation(
          workflowState: wf,
          confirmationQuestion: wf.currentQuestion ??
              const FollowUpQuestion(
                id: 'confirmation_fallback',
                targetField: 'confirmation',
                promptText: 'Please confirm details',
                questionType: GenUiQuestionType.confirmationCard,
              ),
          genUiResponse: genUi,
        );

      case WorkflowStatus.executingAction:
        return ConversationExecutingAction(workflowState: wf, genUiResponse: genUi);

      case WorkflowStatus.completed:
        return ConversationSuccess(
          workflowState: wf,
          result: wf.executionResult,
          successMessage: 'Clinical workflow completed successfully.',
          genUiResponse: genUi,
        );

      case WorkflowStatus.failed:
        return ConversationFailure(
          workflowState: wf,
          errorMessage: wf.errorMessage ?? 'An error occurred during conversational execution.',
          genUiResponse: genUi,
        );
    }
  }

  GenUiResponse _buildGenUiResponseForWorkflow(ConversationWorkflowState wf) {
    final suggestions = suggestionService.resolveSuggestions(
      intent: wf.intent.name,
      workflowStatus: wf.status.name,
      patientId: wf.activePatient?.id.toString(),
      patientName: wf.activePatient?.name,
      hasCompletedAction: wf.status == WorkflowStatus.completed,
      hasMissingInfo: wf.status == WorkflowStatus.awaitingClarification || wf.status == WorkflowStatus.collectingInformation,
      isOptionalQuestion: wf.currentQuestion?.isOptional == true,
    );

    final List<GenUiComponent> components = [];

    // 1. Ambiguous patient selection
    if (wf.candidatePatients.length > 1) {
      components.add(GenUiComponent(
        id: 'patient_disambiguation_card',
        type: GenUiComponentTypes.patientCard,
        data: {
          'title': 'Which patient do you mean?',
          'prompt': 'Multiple patients matched your query. Please select the intended patient:',
        },
        options: wf.candidatePatients.map((p) {
          final age = (DateTime.now().difference(p.dateOfBirth).inDays / 365.25).floor();
          final condition = p.medicalConditions.isNotEmpty ? p.medicalConditions.first : 'General';
          return GenUiOption(
            id: p.id.toString(),
            label: p.name,
            value: p.id,
            subtitle: 'ID: ${p.remoteId} • Age: $age • $condition',
            metadata: {
              'id': p.id,
              'remoteId': p.remoteId,
              'age': age,
              'condition': condition,
            },
          );
        }).toList(),
      ));
    }
    // 2. Awaiting Confirmation (Patient or Vitals)
    else if (wf.status == WorkflowStatus.awaitingConfirmation) {
      if (wf.intent == ConversationIntent.createPatient) {
        components.add(GenUiComponent(
          id: 'editable_patient_card',
          type: GenUiComponentTypes.editablePatientCard,
          data: {
            'name': wf.parameters['name'],
            'age': wf.parameters['age'],
            'complaint': wf.parameters['complaint'],
            'duration': wf.parameters['duration'],
            'bloodPressure': wf.parameters['bloodPressure'],
          },
        ));
      } else if (wf.intent == ConversationIntent.recordVitals) {
        components.add(GenUiComponent(
          id: 'vital_input_card',
          type: GenUiComponentTypes.vitalInputCard,
          data: {
            'patientId': wf.activePatient?.id,
            'patientName': wf.activePatient?.name,
            'systolic': wf.parameters['systolic'],
            'diastolic': wf.parameters['diastolic'],
            'pulse': wf.parameters['pulse'],
            'temperature': wf.parameters['temperature'],
            'spo2': wf.parameters['spo2'],
          },
        ));
      } else {
        components.add(GenUiComponent(
          id: 'confirmation_card',
          type: GenUiComponentTypes.confirmationCard,
          data: {
            'title': 'Confirm Action',
            'summary': 'Please confirm before proceeding with this clinical update.',
            'details': wf.parameters,
          },
        ));
      }
    }
    // 3. Follow-up Question
    else if (wf.currentQuestion != null) {
      final q = wf.currentQuestion!;
      if (q.questionType == GenUiQuestionType.singleChoice || q.questionType == GenUiQuestionType.multiSelect) {
        components.add(GenUiComponent(
          id: q.id,
          type: q.questionType == GenUiQuestionType.multiSelect
              ? GenUiComponentTypes.multipleChoice
              : GenUiComponentTypes.choiceCard,
          data: {
            'prompt': q.promptText,
            'targetField': q.targetField,
            'isMultiple': q.questionType == GenUiQuestionType.multiSelect,
          },
          options: q.options.map((o) {
            return GenUiOption(
              id: o.label,
              label: o.label,
              value: o.value,
              subtitle: o.subtitle,
            );
          }).toList(),
        ));
      } else {
        components.add(GenUiComponent(
          id: q.id,
          type: GenUiComponentTypes.followUpCard,
          data: {
            'prompt': q.promptText,
            'targetField': q.targetField,
            'unit': q.unit,
            'helpText': q.helpText,
            'isOptional': q.isOptional,
          },
        ));
      }
    }
    // 4. Completed Workflow Success
    else if (wf.status == WorkflowStatus.completed) {
      if (wf.intent != ConversationIntent.generalQuery) {
        components.add(GenUiComponent(
          id: 'success_summary_card',
          type: GenUiComponentTypes.successCard,
          data: {
            'message': 'Clinical workflow completed successfully.',
            'details': wf.executionResult != null ? 'Result: ${wf.executionResult}' : null,
          },
        ));
      }
    }

    final String responseMessage;
    if (wf.intent == ConversationIntent.generalQuery && wf.executionResult is String) {
      responseMessage = wf.executionResult as String;
    } else {
      responseMessage = wf.currentQuestion?.promptText ?? wf.lastUserUtterance;
    }

    return GenUiResponse(
      message: responseMessage,
      components: components,
      suggestions: suggestions,
      context: {
        'intent': wf.intent.name,
        'status': wf.status.name,
        'patientId': wf.activePatient?.id,
        'patientName': wf.activePatient?.name,
      },
    );
  }
}
