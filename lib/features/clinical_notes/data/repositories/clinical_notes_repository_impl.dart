import '../../patients/domain/repositories/patient_repository.dart';
import '../../patients/data/models/clinical_note.dart';
import '../../domain/repositories/clinical_notes_repository.dart';

class ClinicalNotesRepositoryImpl implements ClinicalNotesRepository {
  final PatientRepository patientRepository;

  const ClinicalNotesRepositoryImpl({required this.patientRepository});

  @override
  Future<List<ClinicalNote>> getNotes(int patientId) {
    return patientRepository.getClinicalNotes(patientId);
  }

  @override
  Future<void> saveNote(ClinicalNote note) {
    return patientRepository.saveClinicalNote(note);
  }
}
