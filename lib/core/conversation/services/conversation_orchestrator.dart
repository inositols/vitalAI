import '../../../../features/patients/data/models/patient_model.dart';
import '../models/conversation_intent.dart';
import '../models/conversation_workflow_state.dart';
import '../models/follow_up_question.dart';
import '../models/genui_question_type.dart';
import '../models/workflow_status.dart';
import 'action_executor.dart';
import 'follow_up_question_resolver.dart';
import 'intent_resolver.dart';
import 'workflow_validator.dart';

/// Central Universal Conversational Orchestrator.
/// Implements the 10-step universal conversational workflow across all intents.
class ConversationOrchestrator {
  final IntentResolver intentResolver;
  final WorkflowValidator validator;
  final FollowUpQuestionResolver questionResolver;
  final ActionExecutor actionExecutor;

  const ConversationOrchestrator({
    required this.intentResolver,
    required this.validator,
    required this.questionResolver,
    required this.actionExecutor,
  });

  /// Processes natural language utterance from speech or typed text.
  Future<ConversationWorkflowState> handleUserUtterance(
    String utterance,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  ) async {
    final trimmed = utterance.trim();
    if (trimmed.isEmpty) return currentState;
    final lower = trimmed.toLowerCase();

    // 0. Check global conversational interruption commands
    if (_isCancelCommand(lower)) {
      return currentState.copyWith(
        status: WorkflowStatus.cancelled,
        lastUserUtterance: trimmed,
        clearCurrentQuestion: true,
      );
    }

    if (_isBackCommand(lower)) {
      return handleStepBack(currentState);
    }

    // 1. If an interactive workflow is already active:
    if (currentState.status.isInteractive && currentState.currentQuestion != null) {
      return _continueActiveWorkflowWithUtterance(
        trimmed,
        currentState,
        existingPatients,
      );
    }

    // 2. Otherwise, start a new workflow from utterance:
    // Step 1: Understand user's intent
    final intent = intentResolver.classify(trimmed);

    // Step 2: Extract all information already supplied
    final extraction = intentResolver.extractParameters(
      trimmed,
      intent,
      existingPatients: existingPatients,
      currentActivePatient: currentState.activePatient,
    );

    var newParams = Map<String, dynamic>.from(extraction.parameters);
    var candidatePatients = extraction.candidatePatients;
    var resolvedPatient = extraction.resolvedPatient ?? currentState.activePatient;

    if (resolvedPatient != null) {
      newParams['patientId'] = resolvedPatient.id;
      newParams['patientName'] = resolvedPatient.name;
    }

    // Step 3: Validate collected parameters
    final errors = validator.validate(intent, newParams);

    var state = currentState.copyWith(
      status: WorkflowStatus.interpretingRequest,
      intent: intent,
      parameters: newParams,
      activePatient: resolvedPatient,
      candidatePatients: candidatePatients,
      validationErrors: errors,
      lastUserUtterance: trimmed,
      clearErrorMessage: true,
    );

    // Step 4 & 5: Determine next step or follow-up question
    return _advanceWorkflow(state, existingPatients);
  }

  /// Processes an option selection or input submit from an interactive GenUI component.
  Future<ConversationWorkflowState> handleOptionSelection(
    String field,
    dynamic value,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  ) async {
    final updatedParams = Map<String, dynamic>.from(currentState.parameters);
    updatedParams[field] = value;

    PatientModel? newActivePatient = currentState.activePatient;
    List<PatientModel> newCandidates = List.from(currentState.candidatePatients);

    // If selecting a patient
    if (field == 'patientId') {
      final pid = value is int ? value : int.tryParse(value.toString()) ?? 0;
      final matched = existingPatients.where((p) => p.id == pid).toList();
      if (matched.isNotEmpty) {
        newActivePatient = matched.first;
        updatedParams['patientId'] = newActivePatient.id;
        updatedParams['patientName'] = newActivePatient.name;
        newCandidates = [];
      }
    }

    // Run validation
    final errors = validator.validate(currentState.intent, updatedParams);

    // Save history snapshot for undo/back
    final newHistory = List<Map<String, dynamic>>.from(currentState.history)
      ..add({
        'parameters': Map<String, dynamic>.from(currentState.parameters),
        'question': currentState.currentQuestion,
        'status': currentState.status,
      });

    final state = currentState.copyWith(
      parameters: updatedParams,
      activePatient: newActivePatient,
      candidatePatients: newCandidates,
      validationErrors: errors,
      history: newHistory,
      clearErrorMessage: true,
    );

    return _advanceWorkflow(state, existingPatients);
  }

  /// Explicit confirmation action for consequential writes.
  Future<ConversationWorkflowState> handleConfirmation(
    ConversationWorkflowState currentState,
  ) async {
    // Prevent duplicate submissions
    if (currentState.isExecuting) return currentState;

    final executingState = currentState.copyWith(
      status: WorkflowStatus.executingAction,
      isExecuting: true,
      isConfirmed: true,
    );

    // Execute through authorized application layer
    final result = await actionExecutor.executeWorkflowAction(executingState);

    if (result.isSuccess) {
      return executingState.copyWith(
        status: WorkflowStatus.completed,
        isExecuting: false,
        executionResult: result.data,
        clearCurrentQuestion: true,
      );
    } else {
      return executingState.copyWith(
        status: WorkflowStatus.failed,
        isExecuting: false,
        errorMessage: result.errorMessage,
      );
    }
  }

  /// Cancels active workflow.
  ConversationWorkflowState handleCancel(ConversationWorkflowState currentState) {
    return currentState.copyWith(
      status: WorkflowStatus.cancelled,
      clearCurrentQuestion: true,
    );
  }

  /// Steps back to previous state snapshot.
  ConversationWorkflowState handleStepBack(ConversationWorkflowState currentState) {
    if (currentState.history.isEmpty) {
      return currentState.copyWith(status: WorkflowStatus.idle);
    }

    final previous = currentState.history.last;
    final updatedHistory = List<Map<String, dynamic>>.from(currentState.history)..removeLast();

    return currentState.copyWith(
      parameters: previous['parameters'] as Map<String, dynamic>? ?? {},
      currentQuestion: previous['question'] as FollowUpQuestion?,
      status: previous['status'] as WorkflowStatus? ?? WorkflowStatus.collectingInformation,
      history: updatedHistory,
      clearErrorMessage: true,
    );
  }

  /// Internal continuation logic for an in-flight workflow.
  Future<ConversationWorkflowState> _continueActiveWorkflowWithUtterance(
    String utterance,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  ) async {
    final lower = utterance.toLowerCase();
    final question = currentState.currentQuestion!;
    final field = question.targetField;

    // Check for confirmation intent if on confirmation step
    if (currentState.status == WorkflowStatus.awaitingConfirmation ||
        question.questionType == GenUiQuestionType.confirmationCard ||
        question.questionType == GenUiQuestionType.previewCard) {
      if (_isConfirmCommand(lower)) {
        return handleConfirmation(currentState);
      }
    }

    // Check for skip intent on optional fields
    if (question.isOptional && _isSkipCommand(lower)) {
      final updatedParams = Map<String, dynamic>.from(currentState.parameters);
      updatedParams['skip_$field'] = true;
      final state = currentState.copyWith(parameters: updatedParams);
      return _advanceWorkflow(state, existingPatients);
    }

    // Parse value for target field
    dynamic parsedValue;
    switch (question.questionType) {
      case GenUiQuestionType.numericInput:
        final numRegex = RegExp(r'(\d+(?:\.\d+)?)');
        final match = numRegex.firstMatch(utterance);
        if (match != null) {
          parsedValue = double.tryParse(match.group(1)!);
        }
        break;

      case GenUiQuestionType.patientSelection:
        final matches = existingPatients
            .where((p) => p.name.toLowerCase().contains(lower))
            .toList();
        if (matches.length == 1) {
          parsedValue = matches.first.id;
        } else if (matches.length > 1) {
          return currentState.copyWith(
            candidatePatients: matches,
            status: WorkflowStatus.awaitingSelection,
          );
        }
        break;

      case GenUiQuestionType.singleChoice:
        // Try match against options
        for (final opt in question.options) {
          if (opt.label.toLowerCase().contains(lower) ||
              opt.value.toString().toLowerCase() == lower) {
            parsedValue = opt.value;
            break;
          }
        }
        parsedValue ??= utterance;
        break;

      default:
        parsedValue = utterance;
        break;
    }

    if (parsedValue != null) {
      return handleOptionSelection(field, parsedValue, currentState, existingPatients);
    } else {
      // Re-prompt with validation message
      return currentState.copyWith(
        validationErrors: {field: 'Could not understand "$utterance". Please provide a valid value.'},
      );
    }
  }

  /// Advances state: checks if clarification is needed or if ready for confirmation / execution.
  Future<ConversationWorkflowState> _advanceWorkflow(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) async {
    // Step 5: Ask next relevant question
    final nextQuestion = questionResolver.resolveNextQuestion(state, existingPatients);

    if (nextQuestion != null) {
      final WorkflowStatus newStatus;
      if (nextQuestion.questionType == GenUiQuestionType.patientSelection) {
        newStatus = WorkflowStatus.awaitingSelection;
      } else if (nextQuestion.questionType == GenUiQuestionType.confirmationCard ||
          nextQuestion.questionType == GenUiQuestionType.previewCard) {
        newStatus = WorkflowStatus.awaitingConfirmation;
      } else if (nextQuestion.questionType == GenUiQuestionType.ambiguousChoices) {
        newStatus = WorkflowStatus.awaitingClarification;
      } else {
        newStatus = WorkflowStatus.collectingInformation;
      }

      return state.copyWith(
        status: newStatus,
        currentQuestion: nextQuestion,
        availableOptions: nextQuestion.options,
      );
    }

    // Step 8 & 9: No more questions needed!
    // Consequential write requires confirmation
    if (state.intent.isConsequentialWrite && !state.isConfirmed) {
      return state.copyWith(status: WorkflowStatus.awaitingConfirmation);
    }

    // Read-only or pre-confirmed write: Execute directly!
    return handleConfirmation(state);
  }

  bool _isCancelCommand(String lower) {
    return lower == 'cancel' ||
        lower == 'stop' ||
        lower == 'abort' ||
        lower == 'dismiss' ||
        lower == 'nevermind';
  }

  bool _isBackCommand(String lower) {
    return lower == 'back' ||
        lower == 'go back' ||
        lower == 'previous step' ||
        lower == 'undo';
  }

  bool _isConfirmCommand(String lower) {
    return lower == 'confirm' ||
        lower == 'yes' ||
        lower == 'save' ||
        lower == 'proceed' ||
        lower == 'looks good' ||
        lower == 'confirm and save' ||
        lower == 'yes, proceed';
  }

  bool _isSkipCommand(String lower) {
    return lower == 'skip' ||
        lower == 'pass' ||
        lower == 'no' ||
        lower == 'none' ||
        lower == "i don't have it" ||
        lower == 'skip this';
  }
}
