import '../../patients/data/models/clinical_note.dart';
import '../repositories/clinical_notes_repository.dart';

class GetClinicalNotesUseCase {
  final ClinicalNotesRepository repository;

  const GetClinicalNotesUseCase(this.repository);

  Future<List<ClinicalNote>> call(int patientId) => repository.getNotes(patientId);
}

class SaveClinicalNoteUseCase {
  final ClinicalNotesRepository repository;

  const SaveClinicalNoteUseCase(this.repository);

  Future<void> call(ClinicalNote note) => repository.saveNote(note);
}
