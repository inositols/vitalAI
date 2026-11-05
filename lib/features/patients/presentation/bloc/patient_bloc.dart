import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../data/models/patient_model.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'patient_event.dart';
import 'patient_state.dart';

/// Alias for PatientsBloc to support architectural naming conventions.
typedef PatientsBloc = PatientBloc;

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository patientRepository;
  final AuthRepository? authRepository;
  PatientModel? _activePatient;
  StreamSubscription<AuthUser?>? _authSubscription;

  PatientBloc({
    required this.patientRepository,
    this.authRepository,
  }) : super(PatientInitial()) {
    on<PatientListRequested>(_onPatientListRequested);
    on<PatientSelected>(_onPatientSelected);
    on<PatientSaved>(_onPatientSaved);
    on<PatientDeleted>(_onPatientDeleted);

    _authSubscription = authRepository?.authStateChanges.listen((_) {
      _activePatient = null;
      add(PatientListRequested());
    });
  }

  Future<void> _onPatientListRequested(
      PatientListRequested event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      final patients = await patientRepository.getPatients();

      // Refresh active patient if patients exist, otherwise null
      if (patients.isEmpty) {
        _activePatient = null;
      } else if (_activePatient == null) {
        _activePatient = patients.first;
      } else {
        _activePatient = patients.firstWhere(
          (p) => p.id == _activePatient!.id,
          orElse: () => patients.first,
        );
      }
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  Future<void> _onPatientSelected(
      PatientSelected event, Emitter<PatientState> emit) async {
    _activePatient = event.patient;
    try {
      final patients = await patientRepository.getPatients();
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  Future<void> _onPatientSaved(
      PatientSaved event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await patientRepository.savePatient(event.patient);
      _activePatient = event.patient;
      final patients = await patientRepository.getPatients();
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  Future<void> _onPatientDeleted(
      PatientDeleted event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await patientRepository.deletePatient(event.localId, event.remoteId);
      if (_activePatient?.id == event.localId) {
        _activePatient = null;
      }
      final patients = await patientRepository.getPatients();
      if (_activePatient == null && patients.isNotEmpty) {
        _activePatient = patients.first;
      }
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
