import 'package:equatable/equatable.dart';

abstract class PatientCreationEvent extends Equatable {
  const PatientCreationEvent();

  @override
  List<Object?> get props => [];
}

class PatientCreationNameChanged extends PatientCreationEvent {
  final String name;
  const PatientCreationNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class PatientCreationDobChanged extends PatientCreationEvent {
  final DateTime dob;
  const PatientCreationDobChanged(this.dob);

  @override
  List<Object?> get props => [dob];
}

class PatientCreationGenderChanged extends PatientCreationEvent {
  final String gender;
  const PatientCreationGenderChanged(this.gender);

  @override
  List<Object?> get props => [gender];
}

class PatientCreationPhoneChanged extends PatientCreationEvent {
  final String phone;
  const PatientCreationPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

class PatientCreationEmergencyContactChanged extends PatientCreationEvent {
  final String contact;
  const PatientCreationEmergencyContactChanged(this.contact);

  @override
  List<Object?> get props => [contact];
}

class PatientCreationConditionsChanged extends PatientCreationEvent {
  final List<String> conditions;
  const PatientCreationConditionsChanged(this.conditions);

  @override
  List<Object?> get props => [conditions];
}

class PatientCreationAllergiesChanged extends PatientCreationEvent {
  final List<String> allergies;
  const PatientCreationAllergiesChanged(this.allergies);

  @override
  List<Object?> get props => [allergies];
}

class PatientCreationMedicationsChanged extends PatientCreationEvent {
  final List<String> medications;
  const PatientCreationMedicationsChanged(this.medications);

  @override
  List<Object?> get props => [medications];
}

class PatientCreationSubmitted extends PatientCreationEvent {
  const PatientCreationSubmitted();
}

class PatientCreationReset extends PatientCreationEvent {
  const PatientCreationReset();
}
