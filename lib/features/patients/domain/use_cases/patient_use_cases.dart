import '../repositories/patient_repository.dart';
import '../../data/models/patient_model.dart';

/// Use case to retrieve all patients.
class GetPatientsUseCase {
  final PatientRepository repository;

  const GetPatientsUseCase(this.repository);

  Future<List<PatientModel>> call() => repository.getPatients();
}

/// Use case to retrieve a single patient by ID.
class GetPatientByIdUseCase {
  final PatientRepository repository;

  const GetPatientByIdUseCase(this.repository);

  Future<PatientModel?> call(int id) => repository.getPatientById(id);
}

/// Use case to register or save a patient.
class RegisterPatientUseCase {
  final PatientRepository repository;

  const RegisterPatientUseCase(this.repository);

  Future<void> call(PatientModel patient) => repository.savePatient(patient);
}

/// Use case to delete a patient.
class DeletePatientUseCase {
  final PatientRepository repository;

  const DeletePatientUseCase(this.repository);

  Future<void> call(int localId, String remoteId) =>
      repository.deletePatient(localId, remoteId);
}
