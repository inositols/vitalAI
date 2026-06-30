import 'package:vitalai/features/patients/data/models/patient_model.dart';

/// Repository interface for patient profiles management.
abstract class PatientRepository {
  /// Fetch all patient profiles.
  Future<List<PatientModel>> getPatients();

  /// Retrieve a specific patient profile by its local database ID.
  Future<PatientModel?> getPatientById(int id);

  /// Retrieve a specific patient profile by its remote Firestore ID.
  Future<PatientModel?> getPatientByRemoteId(String remoteId);

  /// Add or update a patient profile locally, marking it as unsynced.
  Future<void> savePatient(PatientModel patient);

  /// Remove a patient profile from local database and firestore.
  Future<void> deletePatient(int localId, String remoteId);

  /// Sync local changes to Cloud Firestore when online.
  Future<void> syncPatients();
}
