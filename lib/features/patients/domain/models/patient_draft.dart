import 'package:vitalai/features/patients/data/models/patient_model.dart';

/// Steps in the conversational patient creation workflow.
enum PatientCreationStep {
  name,
  dateOfBirth,
  phone,
  email,
  gender,
  duplicateWarning,
  review,
  completed,
  cancelled,
}

/// Represents the in-progress draft of a new patient record being created
/// via voice or text in the conversational interface.
class PatientDraft {
  final String? name;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? email;
  final String? gender;
  final String? notes;
  final String? identifier;
  final bool recordVitalsAfterCreation;
  final PatientCreationStep currentStep;
  final Set<String> skippedFields;
  final Map<String, String> validationErrors;
  final bool isSaving;
  final bool isConfirmed;
  final PatientModel? potentialDuplicate;
  final PatientModel? createdPatient;
  final String? lastError;

  const PatientDraft({
    this.name,
    this.dateOfBirth,
    this.phone,
    this.email,
    this.gender,
    this.notes,
    this.identifier,
    this.recordVitalsAfterCreation = false,
    this.currentStep = PatientCreationStep.name,
    this.skippedFields = const {},
    this.validationErrors = const {},
    this.isSaving = false,
    this.isConfirmed = false,
    this.potentialDuplicate,
    this.createdPatient,
    this.lastError,
  });

  /// Compute patient age if dateOfBirth is known.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }

  /// Whether all required information (Full Name) is present and validated.
  bool get hasRequiredName => name != null && name!.trim().isNotEmpty;

  /// Check whether the draft has sufficient data to proceed to review.
  bool get isReadyForReview {
    if (!hasRequiredName) return false;
    // Check if remaining fields were either answered or explicitly skipped
    return currentStep == PatientCreationStep.review ||
        currentStep == PatientCreationStep.duplicateWarning ||
        currentStep == PatientCreationStep.completed;
  }

  /// Prompt question string for the assistant to ask based on the current step.
  String get questionForCurrentStep {
    switch (currentStep) {
      case PatientCreationStep.name:
        return "What is the patient's full name?";
      case PatientCreationStep.dateOfBirth:
        final firstName = name?.split(' ').first ?? 'the patient';
        return "What is $firstName's date of birth?";
      case PatientCreationStep.phone:
        final firstName = name?.split(' ').first ?? 'the patient';
        return "What is $firstName's phone number?";
      case PatientCreationStep.email:
        return "Would you like to add an email address for $name?";
      case PatientCreationStep.gender:
        return "What is the patient's biological sex or gender?";
      case PatientCreationStep.duplicateWarning:
        return "A patient with similar details already exists. Would you like to review the existing record or proceed with a new registration?";
      case PatientCreationStep.review:
        return "Please review the patient summary below. Ready to confirm and create this record?";
      case PatientCreationStep.completed:
        return "Patient ${createdPatient?.name ?? name} has been registered successfully.";
      case PatientCreationStep.cancelled:
        return "Patient creation cancelled.";
    }
  }

  /// Convert draft to a PatientModel.
  PatientModel toPatientModel({String? generatedId}) {
    final patient = PatientModel()
      ..name = name?.trim() ?? ''
      ..gender = gender ?? 'Unspecified'
      ..dateOfBirth =
          dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 30))
      ..phone = phone?.trim()
      ..email = email?.trim()
      ..emergencyContact = phone?.trim() ?? ''
      ..notes = notes?.trim()
      ..isSynced = false
      ..updatedAt = DateTime.now();

    if (identifier != null && identifier!.isNotEmpty) {
      patient.remoteId = identifier!;
    } else if (generatedId != null) {
      patient.remoteId = generatedId;
    }
    return patient;
  }

  PatientDraft copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? phone,
    String? email,
    String? gender,
    String? notes,
    String? identifier,
    bool? recordVitalsAfterCreation,
    PatientCreationStep? currentStep,
    Set<String>? skippedFields,
    Map<String, String>? validationErrors,
    bool? isSaving,
    bool? isConfirmed,
    PatientModel? potentialDuplicate,
    PatientModel? createdPatient,
    String? lastError,
  }) {
    return PatientDraft(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      notes: notes ?? this.notes,
      identifier: identifier ?? this.identifier,
      recordVitalsAfterCreation:
          recordVitalsAfterCreation ?? this.recordVitalsAfterCreation,
      currentStep: currentStep ?? this.currentStep,
      skippedFields: skippedFields ?? this.skippedFields,
      validationErrors: validationErrors ?? this.validationErrors,
      isSaving: isSaving ?? this.isSaving,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      potentialDuplicate: potentialDuplicate ?? this.potentialDuplicate,
      createdPatient: createdPatient ?? this.createdPatient,
      lastError: lastError,
    );
  }
}
