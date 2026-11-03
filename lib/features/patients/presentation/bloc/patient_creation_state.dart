import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';

enum PatientCreationStatus { initial, inProgress, success, failure }

class PatientCreationState extends Equatable {
  final String name;
  final DateTime? dob;
  final String gender;
  final String phoneNumber;
  final String emergencyContact;
  final List<String> conditions;
  final List<String> allergies;
  final List<String> medications;
  final Map<String, String> validationErrors;
  final PatientCreationStatus status;
  final String? errorMessage;
  final PatientModel? createdPatient;

  const PatientCreationState({
    this.name = '',
    this.dob,
    this.gender = 'male',
    this.phoneNumber = '',
    this.emergencyContact = '',
    this.conditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.validationErrors = const {},
    this.status = PatientCreationStatus.initial,
    this.errorMessage,
    this.createdPatient,
  });

  bool get isValid => name.trim().isNotEmpty && validationErrors.isEmpty;

  PatientCreationState copyWith({
    String? name,
    DateTime? dob,
    String? gender,
    String? phoneNumber,
    String? emergencyContact,
    List<String>? conditions,
    List<String>? allergies,
    List<String>? medications,
    Map<String, String>? validationErrors,
    PatientCreationStatus? status,
    String? errorMessage,
    PatientModel? createdPatient,
  }) {
    return PatientCreationState(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      validationErrors: validationErrors ?? this.validationErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
      createdPatient: createdPatient ?? this.createdPatient,
    );
  }

  @override
  List<Object?> get props => [
        name,
        dob,
        gender,
        phoneNumber,
        emergencyContact,
        conditions,
        allergies,
        medications,
        validationErrors,
        status,
        errorMessage,
        createdPatient,
      ];
}
