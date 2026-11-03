import '../models/models.dart';
import '../repositories/conversation_repository.dart';

/// Use case to confirm and commit a consequential action.
class ConfirmConversationWorkflowUseCase {
  final ConversationRepository repository;

  const ConfirmConversationWorkflowUseCase(this.repository);

  Future<ConversationWorkflowState> call(ConversationWorkflowState currentState) {
    return repository.handleConfirmation(currentState);
  }
}

/// Use case to cancel the active workflow.
class CancelConversationWorkflowUseCase {
  final ConversationRepository repository;

  const CancelConversationWorkflowUseCase(this.repository);

  ConversationWorkflowState call(ConversationWorkflowState currentState) {
    return repository.handleCancel(currentState);
  }
}

/// Use case to step back (undo) the last workflow step.
class StepBackConversationWorkflowUseCase {
  final ConversationRepository repository;

  const StepBackConversationWorkflowUseCase(this.repository);

  ConversationWorkflowState call(ConversationWorkflowState currentState) {
    return repository.handleStepBack(currentState);
  }
}
