import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';

abstract class PatientEvent extends Equatable {
  const PatientEvent();

  @override
  List<Object?> get props => [];
}

class PatientListRequested extends PatientEvent {}

class PatientSelected extends PatientEvent {
  final PatientModel patient;

  const PatientSelected(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientSaved extends PatientEvent {
  final PatientModel patient;

  const PatientSaved(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientDeleted extends PatientEvent {
  final int localId;
  final String remoteId;

  const PatientDeleted({required this.localId, required this.remoteId});

  @override
  List<Object?> get props => [localId, remoteId];
}
