import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/patient_use_cases.dart';
import '../../data/models/patient_model.dart';
import 'patient_creation_event.dart';
import 'patient_creation_state.dart';

/// Dedicated BLoC managing patient registration and creation workflow.
class PatientCreationBloc extends Bloc<PatientCreationEvent, PatientCreationState> {
  final RegisterPatientUseCase registerPatientUseCase;

  PatientCreationBloc({
    required this.registerPatientUseCase,
    PatientCreationState? initialState,
  }) : super(initialState ?? const PatientCreationState()) {
    on<PatientCreationNameChanged>(_onNameChanged);
    on<PatientCreationDobChanged>(_onDobChanged);
    on<PatientCreationGenderChanged>(_onGenderChanged);
    on<PatientCreationPhoneChanged>(_onPhoneChanged);
    on<PatientCreationEmergencyContactChanged>(_onEmergencyContactChanged);
    on<PatientCreationConditionsChanged>(_onConditionsChanged);
    on<PatientCreationAllergiesChanged>(_onAllergiesChanged);
    on<PatientCreationMedicationsChanged>(_onMedicationsChanged);
    on<PatientCreationSubmitted>(_onSubmitted);
    on<PatientCreationReset>(_onReset);
  }

  void _onNameChanged(
    PatientCreationNameChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    final errors = Map<String, String>.from(state.validationErrors);
    if (event.name.trim().isEmpty) {
      errors['name'] = 'Patient full name is required.';
    } else {
      errors.remove('name');
    }
    emit(state.copyWith(name: event.name, validationErrors: errors));
  }

  void _onDobChanged(
    PatientCreationDobChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    final errors = Map<String, String>.from(state.validationErrors);
    if (event.dob.isAfter(DateTime.now())) {
      errors['dob'] = 'Date of birth cannot be in the future.';
    } else {
      errors.remove('dob');
    }
    emit(state.copyWith(dob: event.dob, validationErrors: errors));
  }

  void _onGenderChanged(
    PatientCreationGenderChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onPhoneChanged(
    PatientCreationPhoneChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(phoneNumber: event.phone));
  }

  void _onEmergencyContactChanged(
    PatientCreationEmergencyContactChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(emergencyContact: event.contact));
  }

  void _onConditionsChanged(
    PatientCreationConditionsChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(conditions: event.conditions));
  }

  void _onAllergiesChanged(
    PatientCreationAllergiesChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(allergies: event.allergies));
  }

  void _onMedicationsChanged(
    PatientCreationMedicationsChanged event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(state.copyWith(medications: event.medications));
  }

  Future<void> _onSubmitted(
    PatientCreationSubmitted event,
    Emitter<PatientCreationState> emit,
  ) async {
    final errors = <String, String>{};
    if (state.name.trim().isEmpty) {
      errors['name'] = 'Patient full name is required.';
    }
    if (state.dob != null && state.dob!.isAfter(DateTime.now())) {
      errors['dob'] = 'Date of birth cannot be in the future.';
    }

    if (errors.isNotEmpty) {
      emit(state.copyWith(
        validationErrors: errors,
        status: PatientCreationStatus.failure,
        errorMessage: errors.values.first,
      ));
      return;
    }

    emit(state.copyWith(status: PatientCreationStatus.inProgress));
    try {
      final newPatient = PatientModel()
        ..name = state.name.trim()
        ..dateOfBirth = state.dob
        ..gender = state.gender
        ..phoneNumber = state.phoneNumber
        ..emergencyContact = state.emergencyContact
        ..medicalConditions = List<String>.from(state.conditions)
        ..allergies = List<String>.from(state.allergies)
        ..medications = List<String>.from(state.medications)
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await registerPatientUseCase(newPatient);

      emit(state.copyWith(
        status: PatientCreationStatus.success,
        createdPatient: newPatient,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PatientCreationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onReset(
    PatientCreationReset event,
    Emitter<PatientCreationState> emit,
  ) {
    emit(const PatientCreationState());
  }
}
