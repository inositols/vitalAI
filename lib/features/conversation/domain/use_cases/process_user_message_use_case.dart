import '../models/models.dart';
import '../repositories/conversation_repository.dart';
import '../../../patients/data/models/patient_model.dart';

/// Use case to process natural language user message (voice or text).
class ProcessUserMessageUseCase {
  final ConversationRepository repository;

  const ProcessUserMessageUseCase(this.repository);

  Future<ConversationWorkflowState> call({
    required String message,
    required ConversationWorkflowState currentState,
    List<PatientModel> existingPatients = const [],
  }) {
    return repository.handleUserUtterance(
      message,
      currentState,
      existingPatients,
    );
  }
}
