import '../../data/models/vital_record.dart';

/// Repository interface handling patient health vitals operations and filtering.
abstract class VitalsRepository {
  /// Retrieve all recorded vitals for a specific patient.
  Future<List<VitalRecord>> getVitals(int patientId);

  /// Fetch vitals logs applying date ranges, category type, and abnormality filters.
  Future<List<VitalRecord>> getFilteredVitals({
    required int patientId,
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    bool? abnormalOnly,
  });

  /// Insert or update a vitals record, flagging it as pending sync.
  Future<void> saveVitalRecord(VitalRecord record);

  /// Remove a record from local Isar cache and remote Firestore.
  Future<void> deleteVitalRecord(int localId, String remoteId);

  /// Sync local changes with Cloud Firestore.
  Future<void> syncVitals();
}
