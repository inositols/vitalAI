import '../models/models.dart';
import '../../../patients/data/models/patient_model.dart';

/// Domain contract for conversation and adaptive workflow orchestration.
abstract class ConversationRepository {
  /// Process a spoken or typed user message, extract slots, validate constraints,
  /// and update the active workflow state.
  Future<ConversationWorkflowState> handleUserUtterance(
    String utterance,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  );

  /// Handle a user selection or answer for a specific follow-up question.
  Future<ConversationWorkflowState> handleOptionSelection(
    String field,
    dynamic value,
    ConversationWorkflowState currentState,
    List<PatientModel> existingPatients,
  );

  /// Handle explicit user confirmation to execute a consequential workflow action.
  Future<ConversationWorkflowState> handleConfirmation(
    ConversationWorkflowState currentState,
  );

  /// Cancel active conversational workflow and restore idle state.
  ConversationWorkflowState handleCancel(ConversationWorkflowState currentState);

  /// Undo the last turn/entry in the conversation history snapshot.
  ConversationWorkflowState handleStepBack(ConversationWorkflowState currentState);

  /// Reset workflow state to default initial idle state.
  ConversationWorkflowState reset();
}
