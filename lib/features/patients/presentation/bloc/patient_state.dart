import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientLoadSuccess extends PatientState {
  final List<PatientModel> patients;
  final PatientModel? activePatient;

  const PatientLoadSuccess({required this.patients, this.activePatient});

  @override
  List<Object?> get props => [patients, activePatient];
}

class PatientFailure extends PatientState {
  final String message;

  const PatientFailure(this.message);

  @override
  List<Object?> get props => [message];
}
