import 'package:vitalai/features/patients/data/models/clinical_note.dart';

export 'package:vitalai/features/patients/data/models/clinical_note.dart';

abstract class ClinicalNotesRepository {
  Future<List<ClinicalNote>> getNotes(int patientId);
  Future<void> saveNote(ClinicalNote note);
}
