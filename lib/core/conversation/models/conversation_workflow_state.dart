import 'package:equatable/equatable.dart';
import '../../../../features/patients/data/models/patient_model.dart';
import 'conversation_intent.dart';
import 'follow_up_question.dart';
import 'workflow_definition.dart';
import 'workflow_status.dart';

/// Immutable state machine model governing all conversational clinical workflows.
class ConversationWorkflowState extends Equatable {
  final WorkflowStatus status;
  final ConversationIntent intent;
  final Map<String, dynamic> parameters;
  final PatientModel? activePatient;
  final List<PatientModel> candidatePatients;
  final FollowUpQuestion? currentQuestion;
  final Map<String, String> validationErrors;
  final List<FollowUpOption> availableOptions;
  final String lastUserUtterance;
  final List<Map<String, dynamic>> history;
  final bool isExecuting;
  final bool isConfirmed;
  final dynamic executionResult;
  final String? errorMessage;
  final DateTime updatedAt;

  ConversationWorkflowState({
    this.status = WorkflowStatus.idle,
    this.intent = ConversationIntent.generalQuery,
    this.parameters = const {},
    this.activePatient,
    this.candidatePatients = const [],
    this.currentQuestion,
    this.validationErrors = const {},
    this.availableOptions = const [],
    this.lastUserUtterance = '',
    this.history = const [],
    this.isExecuting = false,
    this.isConfirmed = false,
    this.executionResult,
    this.errorMessage,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Initial idle state.
  factory ConversationWorkflowState.idle() => ConversationWorkflowState();

  ConversationWorkflowState copyWith({
    WorkflowStatus? status,
    ConversationIntent? intent,
    Map<String, dynamic>? parameters,
    PatientModel? activePatient,
    bool clearActivePatient = false,
    List<PatientModel>? candidatePatients,
    FollowUpQuestion? currentQuestion,
    bool clearCurrentQuestion = false,
    Map<String, String>? validationErrors,
    List<FollowUpOption>? availableOptions,
    String? lastUserUtterance,
    List<Map<String, dynamic>>? history,
    bool? isExecuting,
    bool? isConfirmed,
    dynamic executionResult,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ConversationWorkflowState(
      status: status ?? this.status,
      intent: intent ?? this.intent,
      parameters: parameters ?? this.parameters,
      activePatient: clearActivePatient ? null : (activePatient ?? this.activePatient),
      candidatePatients: candidatePatients ?? this.candidatePatients,
      currentQuestion: clearCurrentQuestion ? null : (currentQuestion ?? this.currentQuestion),
      validationErrors: validationErrors ?? this.validationErrors,
      availableOptions: availableOptions ?? this.availableOptions,
      lastUserUtterance: lastUserUtterance ?? this.lastUserUtterance,
      history: history ?? this.history,
      isExecuting: isExecuting ?? this.isExecuting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      executionResult: executionResult ?? this.executionResult,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      updatedAt: DateTime.now(),
    );
  }

  /// Whether all required fields for the active intent have been collected without validation errors.
  bool get hasAllRequiredParameters {
    final def = WorkflowDefinition.registry[intent];
    if (def == null) return false;
    for (final field in def.requiredFields) {
      final val = parameters[field];
      if (val == null) return false;
      if (val is String && val.trim().isEmpty) return false;
    }
    return validationErrors.isEmpty;
  }

  /// Active workflow definition.
  WorkflowDefinition? get definition => WorkflowDefinition.registry[intent];

  /// Get parameter by key.
  T? getParam<T>(String key) => parameters[key] as T?;

  @override
  List<Object?> get props => [
        status,
        intent,
        parameters,
        activePatient,
        candidatePatients,
        currentQuestion,
        validationErrors,
        availableOptions,
        lastUserUtterance,
        history,
        isExecuting,
        isConfirmed,
        executionResult,
        errorMessage,
      ];
}
