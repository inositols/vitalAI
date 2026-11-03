import '../../../../core/conversation/services/conversation_orchestrator.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../../patients/data/models/patient_model.dart';

/// Data layer implementation of [ConversationRepository] delegating to [ConversationOrchestrator].
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationOrchestrator orchestrator;

  const ConversationRepositoryImpl({required this.orchestrator});

  @override
  Future<ConversationWorkflowState> handleUserUtterance(
    String utterance,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  ) {
    return orchestrator.handleUserUtterance(
      utterance,
      currentState,
      existingPatients,
    );
  }

  @override
  Future<ConversationWorkflowState> handleOptionSelection(
    String field,
    dynamic value,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  ) {
    return orchestrator.handleOptionSelection(
      field,
      value,
      currentState,
      existingPatients,
    );
  }

  @override
  Future<ConversationWorkflowState> handleConfirmation(
    ConversationWorkflowState currentState,
  ) {
    return orchestrator.handleConfirmation(currentState);
  }

  @override
  ConversationWorkflowState handleCancel(ConversationWorkflowState currentState) {
    return orchestrator.handleCancel(currentState);
  }

  @override
  ConversationWorkflowState handleStepBack(ConversationWorkflowState currentState) {
    return orchestrator.handleStepBack(currentState);
  }

  @override
  ConversationWorkflowState reset() {
    return ConversationWorkflowState.idle();
  }
}
