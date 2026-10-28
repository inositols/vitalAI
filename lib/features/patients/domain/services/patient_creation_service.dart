import 'package:flutter/foundation.dart';
import '../../data/models/patient_model.dart';
import '../models/patient_draft.dart';
import '../repositories/patient_repository.dart';
import '../../../activity/data/models/activity_item.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';

/// Application service controlling conversational patient registration,
/// field extraction, validation rules, duplicate detection, and final persistence.
class PatientCreationService {
  /// Start a patient creation workflow from an initial provider utterance.
  PatientDraft startPatientCreation(String utterance, List<PatientModel> existingPatients) {
    bool recordVitals = utterance.toLowerCase().contains('blood pressure') ||
        utterance.toLowerCase().contains('vitals') ||
        utterance.toLowerCase().contains('vital signs');

    var draft = PatientDraft(
      recordVitalsAfterCreation: recordVitals,
      currentStep: PatientCreationStep.name,
    );

    // Extract any information already provided in the opening sentence
    draft = extractFieldsFromUtterance(utterance, draft);

    // Determine the next step based on extracted data
    return advanceDraft(draft, existingPatients);
  }

  /// Extracts multiple fields (name, dob, phone, email, gender) from an utterance.
  PatientDraft extractFieldsFromUtterance(String utterance, PatientDraft currentDraft) {
    String? name = currentDraft.name;
    DateTime? dob = currentDraft.dateOfBirth;
    String? phone = currentDraft.phone;
    String? email = currentDraft.email;
    String? gender = currentDraft.gender;

    // 1. Extract email if present
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final emailMatch = emailRegex.firstMatch(utterance);
    if (emailMatch != null) {
      email = emailMatch.group(0);
    }

    // 2. Extract phone if present
    final phoneRegex = RegExp(r'(?:phone(?:\s*number)?(?:\s*is)?\s*)?(\+?[0-9][0-9\s-]{7,15}[0-9])', caseSensitive: false);
    final phoneMatch = phoneRegex.firstMatch(utterance);
    if (phoneMatch != null) {
      final candidate = phoneMatch.group(1)?.replaceAll(RegExp(r'[\s-]'), '');
      if (candidate != null && candidate.length >= 7 && candidate.length <= 15) {
        phone = phoneMatch.group(1)!.trim();
      }
    }

    // 3. Extract Date of Birth if present
    final extractedDob = parseDateFromUtterance(utterance);
    if (extractedDob != null) {
      dob = extractedDob;
    }

    // 4. Extract Gender if present
    final lower = utterance.toLowerCase();
    if (lower.contains(' female') || lower.contains('woman') || lower.contains('girl')) {
      gender = 'Female';
    } else if (lower.contains(' male') || lower.contains(' man ') || lower.contains('boy')) {
      gender = 'Male';
    }

    // 5. Extract Name if not already set
    if (name == null || name.isEmpty) {
      name = parseNameFromUtterance(utterance);
    }

    return currentDraft.copyWith(
      name: name,
      dateOfBirth: dob,
      phone: phone,
      email: email,
      gender: gender,
    );
  }

  /// Process provider voice or text input for the active draft.
  PatientDraft processUtterance(String utterance, PatientDraft draft, List<PatientModel> existingPatients) {
    final trimmed = utterance.trim();
    final lower = trimmed.toLowerCase();

    // 1. Check for cancel intent
    if (isCancel(lower)) {
      return draft.copyWith(currentStep: PatientCreationStep.cancelled);
    }

    // 2. Check for edit / back intent
    if (lower == 'go back' || lower == 'back' || lower == 'edit' || lower == 'edit details') {
      return draft.copyWith(
        currentStep: draft.currentStep == PatientCreationStep.review
            ? PatientCreationStep.name
            : PatientCreationStep.name,
      );
    }

    // 3. Check for confirmation intent when on review step
    if (draft.currentStep == PatientCreationStep.review || draft.currentStep == PatientCreationStep.duplicateWarning) {
      if (isConfirmation(lower) || lower.contains('proceed') || lower.contains('confirm and create')) {
        return draft.copyWith(isConfirmed: true);
      }
    }

    // 4. Check for skip intent on optional steps
    if (isSkip(lower)) {
      return skipCurrentField(draft, existingPatients);
    }

    // 5. Process input according to current step
    switch (draft.currentStep) {
      case PatientCreationStep.name:
        final parsedName = parseNameFromUtterance(trimmed) ?? trimmed;
        if (parsedName.length < 2) {
          return draft.copyWith(
            validationErrors: {'name': 'Please enter a valid patient full name (at least 2 letters).'},
          );
        }
        var updated = draft.copyWith(
          name: parsedName,
          validationErrors: {},
        );
        // Also check if they included DOB, phone, etc in this response
        updated = extractFieldsFromUtterance(trimmed, updated);
        return advanceDraft(updated, existingPatients);

      case PatientCreationStep.dateOfBirth:
        final parsedDate = parseDateFromUtterance(trimmed);
        if (parsedDate == null) {
          return draft.copyWith(
            validationErrors: {'dateOfBirth': 'Could not understand date. Format: "12 March 1998" or "1998-03-12".'},
          );
        }
        if (parsedDate.isAfter(DateTime.now())) {
          return draft.copyWith(
            validationErrors: {'dateOfBirth': 'Date of birth cannot be in the future.'},
          );
        }
        final updated = draft.copyWith(
          dateOfBirth: parsedDate,
          validationErrors: {},
        );
        return advanceDraft(updated, existingPatients);

      case PatientCreationStep.phone:
        final cleanedPhone = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
        if (cleanedPhone.length < 7) {
          return draft.copyWith(
            validationErrors: {'phone': 'Please enter a valid phone number (at least 7 digits) or say "skip".'},
          );
        }
        final updated = draft.copyWith(
          phone: trimmed,
          validationErrors: {},
        );
        return advanceDraft(updated, existingPatients);

      case PatientCreationStep.email:
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(trimmed)) {
          return draft.copyWith(
            validationErrors: {'email': 'Please enter a valid email address (e.g. name@domain.com) or say "skip".'},
          );
        }
        final updated = draft.copyWith(
          email: trimmed,
          validationErrors: {},
        );
        return advanceDraft(updated, existingPatients);

      case PatientCreationStep.gender:
        String g = 'Other';
        if (lower.contains('female') || lower == 'f' || lower == 'woman') {
          g = 'Female';
        } else if (lower.contains('male') || lower == 'm' || lower == 'man') {
          g = 'Male';
        }
        final updated = draft.copyWith(
          gender: g,
          validationErrors: {},
        );
        return advanceDraft(updated, existingPatients);

      case PatientCreationStep.duplicateWarning:
        if (lower.contains('proceed') || lower.contains('create anyway') || lower.contains('continue') || lower.contains('new')) {
          return draft.copyWith(currentStep: PatientCreationStep.review);
        }
        return draft;

      case PatientCreationStep.review:
        if (isConfirmation(lower)) {
          return draft.copyWith(isConfirmed: true);
        }
        return draft;

      case PatientCreationStep.completed:
      case PatientCreationStep.cancelled:
        return draft;
    }
  }

  /// Skips the current optional field and advances to the next step.
  PatientDraft skipCurrentField(PatientDraft draft, List<PatientModel> existingPatients) {
    final skipped = Set<String>.from(draft.skippedFields);
    switch (draft.currentStep) {
      case PatientCreationStep.dateOfBirth:
        skipped.add('dateOfBirth');
        break;
      case PatientCreationStep.phone:
        skipped.add('phone');
        break;
      case PatientCreationStep.email:
        skipped.add('email');
        break;
      case PatientCreationStep.gender:
        skipped.add('gender');
        break;
      default:
        break;
    }
    final updated = draft.copyWith(
      skippedFields: skipped,
      validationErrors: {},
    );
    return advanceDraft(updated, existingPatients);
  }

  /// Determines and advances to the next unanswered/unskipped step.
  PatientDraft advanceDraft(PatientDraft draft, List<PatientModel> existingPatients) {
    if (draft.name == null || draft.name!.trim().isEmpty) {
      return draft.copyWith(currentStep: PatientCreationStep.name);
    }

    if (draft.dateOfBirth == null && !draft.skippedFields.contains('dateOfBirth')) {
      return draft.copyWith(currentStep: PatientCreationStep.dateOfBirth);
    }

    if (draft.phone == null && !draft.skippedFields.contains('phone')) {
      return draft.copyWith(currentStep: PatientCreationStep.phone);
    }

    if (draft.email == null && !draft.skippedFields.contains('email')) {
      return draft.copyWith(currentStep: PatientCreationStep.email);
    }

    if (draft.gender == null && !draft.skippedFields.contains('gender')) {
      return draft.copyWith(currentStep: PatientCreationStep.gender);
    }

    // All fields addressed! Check for potential duplicate record
    final duplicate = findPotentialDuplicate(draft, existingPatients);
    if (duplicate != null && draft.currentStep != PatientCreationStep.duplicateWarning) {
      return draft.copyWith(
        potentialDuplicate: duplicate,
        currentStep: PatientCreationStep.duplicateWarning,
      );
    }

    return draft.copyWith(currentStep: PatientCreationStep.review);
  }

  /// Finds potential duplicate records by matching phone, email, or exact name.
  PatientModel? findPotentialDuplicate(PatientDraft draft, List<PatientModel> existingPatients) {
    if (draft.name == null) return null;
    final draftNameNorm = draft.name!.trim().toLowerCase();
    final draftPhoneNorm = draft.phone?.replaceAll(RegExp(r'[^0-9]'), '');
    final draftEmailNorm = draft.email?.trim().toLowerCase();

    for (final p in existingPatients) {
      // 1. Phone match (highest confidence)
      if (draftPhoneNorm != null && draftPhoneNorm.isNotEmpty) {
        final pPhone = (p.phone ?? p.emergencyContact).replaceAll(RegExp(r'[^0-9]'), '');
        if (pPhone.isNotEmpty && pPhone == draftPhoneNorm) {
          return p;
        }
      }

      // 2. Email match
      if (draftEmailNorm != null && draftEmailNorm.isNotEmpty) {
        if (p.email?.trim().toLowerCase() == draftEmailNorm) {
          return p;
        }
      }

      // 3. Exact Name match (warning, not auto-merge)
      if (p.name.trim().toLowerCase() == draftNameNorm) {
        return p;
      }
    }
    return null;
  }

  /// Saves the confirmed draft to the repository and logs the clinical activity.
  Future<PatientDraft> confirmAndSavePatient(
    PatientDraft draft,
    PatientRepository repository, {
    ActivityBloc? activityBloc,
  }) async {
    if (draft.isSaving) return draft; // Prevent double submission
    if (draft.name == null || draft.name!.trim().isEmpty) {
      return draft.copyWith(lastError: 'Cannot save patient without a name.');
    }

    try {
      // Generate ID like CV-10029
      final patients = await repository.getPatients();
      final nextNum = 10024 + patients.length;
      final generatedId = 'CV-$nextNum';

      final patient = draft.toPatientModel(generatedId: generatedId);
      await repository.savePatient(patient);

      // Log clinical activity
      activityBloc?.add(
        ActivityLogged(
          ActivityItem(
            title: 'Patient registered',
            subtitle: '${patient.name} (${patient.remoteId})',
            timestamp: DateTime.now(),
            category: ActivityCategory.patients,
            patientId: patient.id,
            patientName: patient.name,
            statusBadge: 'Active',
          ),
        ),
      );

      return draft.copyWith(
        isSaving: false,
        isConfirmed: true,
        currentStep: PatientCreationStep.completed,
        createdPatient: patient,
      );
    } catch (e) {
      debugPrint('Save patient failed: $e');
      return draft.copyWith(
        isSaving: false,
        lastError: 'Failed to save patient record: $e. You can tap retry.',
      );
    }
  }

  // --- Natural language parsing helpers ---

  static bool isSkip(String s) {
    final lower = s.toLowerCase();
    return lower == 'skip' ||
        lower == 'pass' ||
        lower == 'no' ||
        lower == 'none' ||
        lower.contains("don't have") ||
        lower.contains('dont have') ||
        lower.contains("don't know") ||
        lower.contains('dont know') ||
        lower.contains('not available') ||
        lower.contains('no phone') ||
        lower.contains('no email') ||
        lower.contains('later') ||
        lower == 'not now';
  }

  static bool isCancel(String s) {
    return s == 'cancel' || s == 'abort' || s == 'stop' || s == 'never mind' || s == 'discard';
  }

  static bool isConfirmation(String s) {
    return s == 'confirm' ||
        s == 'yes' ||
        s == 'save' ||
        s == 'looks good' ||
        s == 'confirm and save' ||
        s == 'confirm and create' ||
        s == 'create' ||
        s == 'create patient';
  }

  /// Parses date from natural language (e.g. "12 March 1998", "March 12, 1998", "1998-03-12", "12/03/1998")
  static DateTime? parseDateFromUtterance(String text) {
    // 1. ISO format: 1998-03-12
    final isoRegex = RegExp(r'\b(19\d{2}|20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b');
    final isoMatch = isoRegex.firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 2. Day Month Year: e.g. "12 March 1998" or "12th of March 1998"
    final dmyRegex = RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?(?:\s+of)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[,]?\s+(19\d{2}|20\d{2})\b',
      caseSensitive: false,
    );
    final dmyMatch = dmyRegex.firstMatch(text);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = _monthNameToNumber(dmyMatch.group(2)!);
      final y = int.parse(dmyMatch.group(3)!);
      if (m != null) return DateTime(y, m, d);
    }

    // 3. Month Day Year: e.g. "March 12 1998", "March 12, 1998"
    final mdyRegex = RegExp(
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?[,]?\s+(19\d{2}|20\d{2})\b',
      caseSensitive: false,
    );
    final mdyMatch = mdyRegex.firstMatch(text);
    if (mdyMatch != null) {
      final m = _monthNameToNumber(mdyMatch.group(1)!);
      final d = int.parse(mdyMatch.group(2)!);
      final y = int.parse(mdyMatch.group(3)!);
      if (m != null) return DateTime(y, m, d);
    }

    // 4. Age expression: e.g. "30 years old", "age 30"
    final ageRegex = RegExp(r'\b(?:age\s+)?(\d{1,3})\s*(?:years?\s*old|yo)\b', caseSensitive: false);
    final ageMatch = ageRegex.firstMatch(text);
    if (ageMatch != null) {
      final age = int.tryParse(ageMatch.group(1)!);
      if (age != null && age > 0 && age < 125) {
        final now = DateTime.now();
        return DateTime(now.year - age, now.month, now.day);
      }
    }

    return null;
  }

  static int? _monthNameToNumber(String name) {
    switch (name.toLowerCase()) {
      case 'january':
      case 'jan':
        return 1;
      case 'february':
      case 'feb':
        return 2;
      case 'march':
      case 'mar':
        return 3;
      case 'april':
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'june':
      case 'jun':
        return 6;
      case 'july':
      case 'jul':
        return 7;
      case 'august':
      case 'aug':
        return 8;
      case 'september':
      case 'sep':
        return 9;
      case 'october':
      case 'oct':
        return 10;
      case 'november':
      case 'nov':
        return 11;
      case 'december':
      case 'dec':
        return 12;
      default:
        return null;
    }
  }

  /// Parses patient name from utterance such as:
  /// - "Add Chika Okafor as a patient"
  /// - "Register a patient named Chika"
  /// - "Create a patient named Johnathan Doe"
  /// - "Register patient Sarah Connor"
  /// - "Create Chika Okafor, born 12 March 1998"
  static String? parseNameFromUtterance(String utterance) {
    // 1. Pattern: "named [Name]"
    final namedRegex = RegExp(r'(?:named|called)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)', caseSensitive: false);
    final namedMatch = namedRegex.firstMatch(utterance);
    if (namedMatch != null) {
      return _cleanName(namedMatch.group(1)!);
    }

    // 2. Pattern: "Register/create/add (a) patient (named) [Name]"
    final registerPatientRegex = RegExp(r'(?:register|create|add)\s+(?:a\s+)?patient\s+(?:named\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)?)', caseSensitive: false);
    final registerMatch = registerPatientRegex.firstMatch(utterance);
    if (registerMatch != null) {
      final cand = registerMatch.group(1)!.trim();
      if (!cand.toLowerCase().startsWith('and ') && !cand.toLowerCase().startsWith('with ')) {
        return _cleanName(cand);
      }
    }

    // 3. Pattern: "Add [Name] as a patient"
    final addAsRegex = RegExp(r'(?:add|register|create)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(?:as a patient|as patient)', caseSensitive: false);
    final addAsMatch = addAsRegex.firstMatch(utterance);
    if (addAsMatch != null) {
      return _cleanName(addAsMatch.group(1)!);
    }

    // 4. Pattern: "Create [Name], born..."
    final createCommaRegex = RegExp(r'(?:create|add|register)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)(?:,|\s+born|\s+with|\s+phone)', caseSensitive: false);
    final createCommaMatch = createCommaRegex.firstMatch(utterance);
    if (createCommaMatch != null) {
      final cand = createCommaMatch.group(1)!.trim();
      if (!cand.toLowerCase().contains('patient') && !cand.toLowerCase().contains('new')) {
        return _cleanName(cand);
      }
    }

    return null;
  }

  static String? _cleanName(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'\b(?:new|patient|a|as|the)\b', caseSensitive: false), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length >= 2) {
      // Capitalize first letters
      return cleaned
          .split(' ')
          .where((s) => s.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
    }
    return null;
  }
}
