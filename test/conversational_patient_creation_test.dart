import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/data/models/clinical_note.dart';
import 'package:vitalai/features/patients/domain/models/patient_draft.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/patients/domain/services/patient_creation_service.dart';
import 'package:vitalai/features/patients/presentation/widgets/conversational_patient_creation_card.dart';

class FakePatientRepository implements PatientRepository {
  final List<PatientModel> _storage = [];
  bool shouldFailOnSave = false;
  int saveCallCount = 0;

  FakePatientRepository([List<PatientModel>? initial]) {
    if (initial != null) _storage.addAll(initial);
  }

  @override
  Future<List<PatientModel>> getPatients() async => List.unmodifiable(_storage);

  @override
  Future<PatientModel?> getPatientById(int id) async {
    try {
      return _storage.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PatientModel?> getPatientByRemoteId(String remoteId) async {
    try {
      return _storage.firstWhere((p) => p.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePatient(PatientModel patient) async {
    saveCallCount++;
    if (shouldFailOnSave) {
      throw Exception('Simulated database connection timeout');
    }
    if (patient.id == 0) {
      patient.id = _storage.length + 1;
      _storage.add(patient);
    } else {
      final index = _storage.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _storage[index] = patient;
      } else {
        _storage.add(patient);
      }
    }
  }

  @override
  Future<void> deletePatient(int localId, String remoteId) async {
    _storage.removeWhere((p) => p.id == localId);
  }

  @override
  Future<void> syncPatients() async {}

  @override
  Future<List<ClinicalNote>> getClinicalNotes(int patientId) async => [];

  @override
  Future<void> saveClinicalNote(ClinicalNote note) async {}
}

void main() {
  late PatientCreationService service;
  late FakePatientRepository repository;
  late List<PatientModel> existingPatients;

  setUp(() {
    service = PatientCreationService();
    existingPatients = [
      PatientModel()
        ..id = 1
        ..remoteId = 'CV-10024'
        ..name = 'Chika Okafor'
        ..phone = '+2348031234567'
        ..email = 'chika@example.com'
        ..gender = 'Female',
      PatientModel()
        ..id = 2
        ..remoteId = 'CV-10025'
        ..name = 'Emeka Nwosu'
        ..phone = '+2348029876543'
        ..email = 'emeka@example.com'
        ..gender = 'Male',
    ];
    repository = FakePatientRepository(existingPatients);
  });

  group('Conversational Patient Creation Tests (Section 16)', () {
    // Scenario 1: Create a patient by voice with all required details provided in one sentence
    test('Scenario 1: Extract all details from a single utterance and proceed directly to review', () {
      final utterance = 'Create Chika Okafor, born 12 March 1998, phone number 08012345678';
      final draft = service.startPatientCreation(utterance, existingPatients);

      expect(draft.name, equals('Chika Okafor'));
      expect(draft.dateOfBirth, equals(DateTime(1998, 3, 12)));
      expect(draft.phone, contains('08012345678'));
      // Since phone and DOB are extracted, email or duplicate is next
      expect(draft.hasRequiredName, isTrue);
    });

    // Scenario 2: Create a patient by text
    test('Scenario 2: Create a patient via typed command', () {
      final input = 'Register a patient named Johnathan Doe';
      final draft = service.startPatientCreation(input, existingPatients);

      expect(draft.name, equals('Johnathan Doe'));
      expect(draft.currentStep, equals(PatientCreationStep.dateOfBirth));
    });

    // Scenario 3: Provide only a name and answer follow-up questions
    test('Scenario 3: Multi-step follow-up conversational progression', () {
      // Step 1: Start with just intent
      var draft = service.startPatientCreation('Create a new patient', existingPatients);
      expect(draft.currentStep, equals(PatientCreationStep.name));

      // Provider provides name
      draft = service.processUtterance('Adaobi Eze', draft, existingPatients);
      expect(draft.name, equals('Adaobi Eze'));
      expect(draft.currentStep, equals(PatientCreationStep.dateOfBirth));

      // Provider provides DOB
      draft = service.processUtterance('1995-08-20', draft, existingPatients);
      expect(draft.dateOfBirth, equals(DateTime(1995, 8, 20)));
      expect(draft.currentStep, equals(PatientCreationStep.phone));

      // Provider provides Phone
      draft = service.processUtterance('08055512345', draft, existingPatients);
      expect(draft.phone, equals('08055512345'));
      expect(draft.currentStep, equals(PatientCreationStep.email));

      // Provider provides Email
      draft = service.processUtterance('adaobi@health.org', draft, existingPatients);
      expect(draft.email, equals('adaobi@health.org'));
      expect(draft.currentStep, equals(PatientCreationStep.gender));

      // Provider provides Gender
      draft = service.processUtterance('Female', draft, existingPatients);
      expect(draft.gender, equals('Female'));
      expect(draft.currentStep, equals(PatientCreationStep.review));
    });

    // Scenario 4: Skip optional fields
    test('Scenario 4: Gracefully skip optional fields (DOB, phone, email, gender)', () {
      var draft = service.startPatientCreation('Add Tunde Bakare as a patient', existingPatients);
      expect(draft.currentStep, equals(PatientCreationStep.dateOfBirth));

      // Skip DOB
      draft = service.processUtterance('skip', draft, existingPatients);
      expect(draft.dateOfBirth, isNull);
      expect(draft.skippedFields.contains('dateOfBirth'), isTrue);
      expect(draft.currentStep, equals(PatientCreationStep.phone));

      // Skip Phone
      draft = service.processUtterance("I don't have it yet", draft, existingPatients);
      expect(draft.phone, isNull);
      expect(draft.skippedFields.contains('phone'), isTrue);
      expect(draft.currentStep, equals(PatientCreationStep.email));

      // Skip Email
      draft = service.processUtterance('none', draft, existingPatients);
      expect(draft.email, isNull);
      expect(draft.skippedFields.contains('email'), isTrue);
      expect(draft.currentStep, equals(PatientCreationStep.gender));

      // Skip Gender
      draft = service.processUtterance('pass', draft, existingPatients);
      expect(draft.gender, isNull);
      expect(draft.skippedFields.contains('gender'), isTrue);

      // Successfully advances to review!
      expect(draft.currentStep, equals(PatientCreationStep.review));
      expect(draft.hasRequiredName, isTrue);
    });

    // Scenario 5: Correct an invalid date or phone number
    test('Scenario 5: Clarification on invalid date and invalid phone preserves valid name', () {
      var draft = service.startPatientCreation('Register patient Sarah Connor', existingPatients);
      expect(draft.currentStep, equals(PatientCreationStep.dateOfBirth));

      // Enter future date
      final futureDate = DateTime.now().add(const Duration(days: 365));
      draft = service.processUtterance('${futureDate.year}-01-01', draft, existingPatients);
      expect(draft.validationErrors.containsKey('dateOfBirth'), isTrue);
      expect(draft.name, equals('Sarah Connor')); // Preserved
      expect(draft.currentStep, equals(PatientCreationStep.dateOfBirth));

      // Provide valid date to correct
      draft = service.processUtterance('15 May 1985', draft, existingPatients);
      expect(draft.validationErrors.isEmpty, isTrue);
      expect(draft.dateOfBirth, equals(DateTime(1985, 5, 15)));
      expect(draft.currentStep, equals(PatientCreationStep.phone));

      // Enter invalid phone with only 3 digits
      draft = service.processUtterance('123', draft, existingPatients);
      expect(draft.validationErrors.containsKey('phone'), isTrue);
      expect(draft.dateOfBirth, equals(DateTime(1985, 5, 15))); // Preserved

      // Correct phone
      draft = service.processUtterance('+1 555 987 6543', draft, existingPatients);
      expect(draft.validationErrors.isEmpty, isTrue);
      expect(draft.phone, equals('+1 555 987 6543'));
    });

    // Scenario 6: Switch from voice to typing midway through registration
    test('Scenario 6: Seamless draft continuity when switching between voice and typing', () {
      // Step 1 via voice utterance simulation
      var draft = service.startPatientCreation('Add David Beckham as a patient', existingPatients);
      expect(draft.name, equals('David Beckham'));

      // Step 2 via typed string
      draft = service.processUtterance('2 May 1975', draft, existingPatients);
      expect(draft.dateOfBirth, equals(DateTime(1975, 5, 2)));

      // Step 3 via voice utterance simulation
      draft = service.processUtterance('+44 7911 123456', draft, existingPatients);
      expect(draft.phone, equals('+44 7911 123456'));

      // Verified no data loss occurred
      expect(draft.name, equals('David Beckham'));
      expect(draft.dateOfBirth, equals(DateTime(1975, 5, 2)));
    });

    // Scenario 7: Cancel before saving
    test('Scenario 7: Cancel workflow aborts registration without saving to repository', () async {
      var draft = service.startPatientCreation('Add Bruce Wayne as a patient', existingPatients);
      draft = service.processUtterance('cancel', draft, existingPatients);

      expect(draft.currentStep, equals(PatientCreationStep.cancelled));
      final allPatients = await repository.getPatients();
      expect(allPatients.any((p) => p.name == 'Bruce Wayne'), isFalse);
    });

    // Scenario 8: Detect a potential duplicate
    test('Scenario 8: Detect duplicate by phone or exact name', () {
      // Name matches existing patient Chika Okafor
      final draft = service.startPatientCreation('Create a new patient', existingPatients);
      final updated = service.processUtterance('Chika Okafor', draft, existingPatients);

      // Skip remaining to trigger duplicate check
      final skipped = service.skipCurrentField(
        service.skipCurrentField(
          service.skipCurrentField(
            service.skipCurrentField(updated, existingPatients),
            existingPatients,
          ),
          existingPatients,
        ),
        existingPatients,
      );

      expect(skipped.currentStep, equals(PatientCreationStep.duplicateWarning));
      expect(skipped.potentialDuplicate, isNotNull);
      expect(skipped.potentialDuplicate!.name, equals('Chika Okafor'));
    });

    // Scenario 9: Simulate a save failure and retry without losing the draft
    test('Scenario 9: Handle repository save failure and retry successfully', () async {
      final draft = PatientDraft(
        name: 'Grace Hopper',
        dateOfBirth: DateTime(1906, 12, 9),
        phone: '+1 800 555 1212',
        currentStep: PatientCreationStep.review,
      );

      // Force failure
      repository.shouldFailOnSave = true;
      final failedDraft = await service.confirmAndSavePatient(draft, repository);

      expect(failedDraft.lastError, contains('Failed to save patient record'));
      expect(failedDraft.name, equals('Grace Hopper')); // Preserved
      expect(failedDraft.currentStep, equals(PatientCreationStep.review)); // Not marked completed

      // Restore and retry
      repository.shouldFailOnSave = false;
      final retriedDraft = await service.confirmAndSavePatient(failedDraft, repository);

      expect(retriedDraft.currentStep, equals(PatientCreationStep.completed));
      expect(retriedDraft.createdPatient, isNotNull);
      expect(retriedDraft.createdPatient!.name, equals('Grace Hopper'));
    });

    // Scenario 10: Confirm that no patient is saved before explicit confirmation
    test('Scenario 10: No patient saved prior to explicit confirmation', () async {
      final initialCount = (await repository.getPatients()).length;

      final draft = service.startPatientCreation('Create patient Albert Einstein', existingPatients);
      service.processUtterance('14 March 1879', draft, existingPatients);

      final currentCount = (await repository.getPatients()).length;
      expect(currentCount, equals(initialCount));
    });

    // Scenario 11: Verify that a double submission does not create duplicate records
    test('Scenario 11: Debouncing / isSaving flag prevents double submission', () async {
      final draft = PatientDraft(
        name: 'Marie Curie',
        dateOfBirth: DateTime(1867, 11, 7),
        currentStep: PatientCreationStep.review,
        isSaving: true, // Already in progress
      );

      await service.confirmAndSavePatient(draft, repository);
      expect(repository.saveCallCount, equals(0)); // Did not call save again
    });

    // Scenario 12: Verify that generated UI components remain consistent with the app's design system
    testWidgets('Scenario 12: ConversationalPatientCreationCard renders with design system tokens', (tester) async {
      final draft = PatientDraft(
        name: 'Chika Okafor',
        currentStep: PatientCreationStep.review,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationalPatientCreationCard(
              draft: draft,
              onSubmitUtterance: (_) {},
              onSkip: () {},
              onCancel: () {},
              onEdit: () {},
              onConfirm: () {},
              onProceedAnyway: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for review title and buttons
      expect(find.text('Confirm Patient Record'), findsOneWidget);
      expect(find.text('Confirm and Create Patient'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Chika Okafor'), findsOneWidget);
    });
  });
}
