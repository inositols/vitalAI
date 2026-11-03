import '../models/models.dart';
import '../repositories/conversation_repository.dart';
import '../../../patients/data/models/patient_model.dart';

/// Use case to submit an answer or selection to a clarifying follow-up question.
class SubmitClarificationUseCase {
  final ConversationRepository repository;

  const SubmitClarificationUseCase(this.repository);

  Future<ConversationWorkflowState> call({
    required String field,
    required dynamic value,
    required ConversationWorkflowState currentState,
    List<PatientModel> existingPatients = const [],
  }) {
    return repository.handleOptionSelection(
      field,
      value,
      currentState,
      existingPatients,
    );
  }
}
