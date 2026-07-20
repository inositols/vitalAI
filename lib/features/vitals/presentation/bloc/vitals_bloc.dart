import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/vitals_repository.dart';
import 'vitals_event.dart';
import 'vitals_state.dart';

class VitalsBloc extends Bloc<VitalsEvent, VitalsState> {
  final VitalsRepository _vitalsRepository;

  VitalsBloc({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        super(VitalsInitial()) {
    on<VitalsListRequested>(_onVitalsListRequested);
    on<VitalsFilteredRequested>(_onVitalsFilteredRequested);
    on<VitalsRecordSaved>(_onVitalsRecordSaved);
    on<VitalsRecordDeleted>(_onVitalsRecordDeleted);
    on<VitalsSyncRequested>(_onVitalsSyncRequested);
  }

  Future<void> _onVitalsListRequested(
      VitalsListRequested event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      final records = await _vitalsRepository.getVitals(event.patientId);
      emit(VitalsLoadSuccess(records));
    } catch (e) {
      emit(VitalsFailure(e.toString()));
    }
  }

  Future<void> _onVitalsFilteredRequested(
      VitalsFilteredRequested event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      final records = await _vitalsRepository.getFilteredVitals(
        patientId: event.patientId,
        vitalType: event.vitalType,
        startDate: event.startDate,
        endDate: event.endDate,
        abnormalOnly: event.abnormalOnly,
      );
      emit(VitalsLoadSuccess(records));
    } catch (e) {
      emit(VitalsFailure(e.toString()));
    }
  }

  Future<void> _onVitalsRecordSaved(
      VitalsRecordSaved event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      await _vitalsRepository.saveVitalRecord(event.record);
      final records = await _vitalsRepository.getVitals(event.record.patientId);
      emit(VitalsLoadSuccess(records));
    } catch (e) {
      emit(VitalsFailure(e.toString()));
    }
  }

  Future<void> _onVitalsRecordDeleted(
      VitalsRecordDeleted event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      await _vitalsRepository.deleteVitalRecord(event.localId, event.remoteId);
      final records = await _vitalsRepository.getVitals(event.patientId);
      emit(VitalsLoadSuccess(records));
    } catch (e) {
      emit(VitalsFailure(e.toString()));
    }
  }

  Future<void> _onVitalsSyncRequested(
      VitalsSyncRequested event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      await _vitalsRepository.syncVitals();
      final records = await _vitalsRepository.getVitals(event.patientId);
      emit(VitalsLoadSuccess(records));
    } catch (e) {
      emit(VitalsFailure(e.toString()));
    }
  }
}
