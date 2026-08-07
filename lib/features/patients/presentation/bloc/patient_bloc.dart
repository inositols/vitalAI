import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../data/models/patient_model.dart';
import 'patient_event.dart';
import 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository _patientRepository;
  PatientModel? _activePatient;

  PatientBloc({required this._patientRepository})
      : super(PatientInitial()) {
    on<PatientListRequested>(_onPatientListRequested);
    on<PatientSelected>(_onPatientSelected);
    on<PatientSaved>(_onPatientSaved);
    on<PatientDeleted>(_onPatientDeleted);
  }

  Future<void> _onPatientListRequested(
      PatientListRequested event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      final patients = await _patientRepository.getPatients();
      // Auto-select first patient if none selected
      if (_activePatient == null && patients.isNotEmpty) {
        _activePatient = patients.first;
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
      final patients = await _patientRepository.getPatients();
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  Future<void> _onPatientSaved(
      PatientSaved event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await _patientRepository.savePatient(event.patient);
      _activePatient = event.patient;
      final patients = await _patientRepository.getPatients();
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }

  Future<void> _onPatientDeleted(
      PatientDeleted event, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await _patientRepository.deletePatient(event.localId, event.remoteId);
      if (_activePatient?.id == event.localId) {
        _activePatient = null;
      }
      final patients = await _patientRepository.getPatients();
      if (_activePatient == null && patients.isNotEmpty) {
        _activePatient = patients.first;
      }
      emit(PatientLoadSuccess(patients: patients, activePatient: _activePatient));
    } catch (e) {
      emit(PatientFailure(e.toString()));
    }
  }
}
