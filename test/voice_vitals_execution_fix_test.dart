import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalai/core/conversation/models/conversation_intent.dart';
import 'package:vitalai/core/conversation/models/conversation_workflow_state.dart';
import 'package:vitalai/core/conversation/models/genui_question_type.dart';
import 'package:vitalai/core/conversation/models/workflow_status.dart';
import 'package:vitalai/core/conversation/services/action_executor.dart';
import 'package:vitalai/core/conversation/services/conversation_orchestrator.dart';
import 'package:vitalai/core/conversation/services/follow_up_question_resolver.dart';
import 'package:vitalai/core/conversation/services/intent_resolver.dart';
import 'package:vitalai/core/conversation/services/workflow_validator.dart';
import 'package:vitalai/core/database/db_service.dart';
import 'package:vitalai/features/activity/data/models/activity_item.dart';
import 'package:vitalai/features/activity/domain/repositories/activity_repository.dart';
import 'package:vitalai/features/patients/data/models/clinical_note.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/reminders/data/models/reminder_model.dart';
import 'package:vitalai/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';

// --- MOCK REPOSITORIES ---

class MemoryPatientRepository implements PatientRepository {
  final List<PatientModel> list = [];
  final Map<int, List<ClinicalNote>> notesStorage = {};

  @override
  Future<List<PatientModel>> getPatients() async => List.unmodifiable(list);

  @override
  Future<PatientModel?> getPatientById(int id) async {
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PatientModel?> getPatientByRemoteId(String remoteId) async {
    try {
      return list.firstWhere((p) => p.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePatient(PatientModel patient) async {
    if (patient.id == 0) {
      patient.id = list.length + 1;
      list.add(patient);
    } else {
      final idx = list.indexWhere((p) => p.id == patient.id);
      if (idx != -1) {
        list[idx] = patient;
      } else {
        list.add(patient);
      }
    }
  }

  @override
  Future<void> deletePatient(int localId, String remoteId) async {
    list.removeWhere((p) => p.id == localId);
  }

  @override
  Future<void> syncPatients() async {}

  @override
  Future<List<ClinicalNote>> getClinicalNotes(int patientId) async =>
      notesStorage[patientId] ?? [];

  @override
  Future<void> saveClinicalNote(ClinicalNote note) async {
    notesStorage.putIfAbsent(note.patientId, () => []).add(note);
  }
}

class MemoryVitalsRepository implements VitalsRepository {
  final List<VitalRecord> vitals = [];

  @override
  Future<List<VitalRecord>> getVitals(int patientId) async {
    return vitals.where((v) => v.patientId == patientId).toList();
  }

  @override
  Future<List<VitalRecord>> getFilteredVitals({
    required int patientId,
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    bool? abnormalOnly,
  }) async {
    return vitals.where((v) => v.patientId == patientId).toList();
  }

  @override
  Future<void> saveVitalRecord(VitalRecord record) async {
    if (record.id == 0) record.id = vitals.length + 1;
    vitals.add(record);
  }

  @override
  Future<void> deleteVitalRecord(int localId, String remoteId) async {
    vitals.removeWhere((v) => v.id == localId);
  }

  @override
  Future<void> syncVitals() async {}
}

class MemoryReminderRepository implements ReminderRepository {
  final List<ReminderModel> reminders = [];

  @override
  Future<List<ReminderModel>> getReminders(int patientId) async => reminders;

  @override
  Future<void> addReminder(ReminderModel reminder) async => reminders.add(reminder);

  @override
  Future<void> saveReminder(ReminderModel reminder) async => reminders.add(reminder);

  @override
  Future<void> deleteReminder(String id, int patientId) async =>
      reminders.removeWhere((r) => r.id == id && r.patientId == patientId);

  @override
  Future<void> updateReminder(ReminderModel reminder) async {}

  @override
  Future<void> toggleReminderCompletion(String id, int patientId) async {}
}

class MemoryActivityRepository implements ActivityRepository {
  final List<ActivityItem> logs = [];

  @override
  Future<List<ActivityItem>> getActivities({ActivityCategory category = ActivityCategory.all}) async =>
      logs;

  @override
  Future<void> logActivity(ActivityItem activity) async => logs.add(activity);

  @override
  Future<void> clearActivities() async => logs.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Priority 5: Patient Data Isolation by Provider UID in DbService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Provider A and Provider B maintain strictly isolated patient databases', () async {
      String? currentUid = 'provider_A';
      final db = DbService(
        const FlutterSecureStorage(),
        currentUserIdProvider: () => currentUid,
      );
      await db.init();

      // Provider A adds Chika Okafor
      final pA = PatientModel()..name = 'Chika Okafor';
      await db.savePatients([pA]);

      final providerAPatients = await db.getPatients();
      expect(providerAPatients.length, equals(1));
      expect(providerAPatients.first.name, equals('Chika Okafor'));

      // Switch session to Provider B (fresh login)
      currentUid = 'provider_B';
      final providerBPatients = await db.getPatients();
      // Must be completely empty, zero demo/leaked patients!
      expect(providerBPatients.isEmpty, isTrue);

      // Provider B adds John Doe
      final pB = PatientModel()..name = 'John Doe';
      await db.savePatients([pB]);

      final providerBUpdated = await db.getPatients();
      expect(providerBUpdated.length, equals(1));
      expect(providerBUpdated.first.name, equals('John Doe'));

      // Switch back to Provider A
      currentUid = 'provider_A';
      final providerARecheck = await db.getPatients();
      expect(providerARecheck.length, equals(1));
      expect(providerARecheck.first.name, equals('Chika Okafor'));
    });
  });

  group('Priority 2 & 6: Voice Assistant Patient Creation with Complete Slots', () {
    late IntentResolver intentResolver;
    late WorkflowValidator validator;
    late FollowUpQuestionResolver questionResolver;
    late MemoryPatientRepository patientRepo;
    late MemoryVitalsRepository vitalsRepo;
    late MemoryReminderRepository reminderRepo;
    late MemoryActivityRepository activityRepo;
    late ActionExecutor actionExecutor;
    late ConversationOrchestrator orchestrator;

    setUp(() {
      intentResolver = const IntentResolver();
      validator = const WorkflowValidator();
      questionResolver = const FollowUpQuestionResolver();
      patientRepo = MemoryPatientRepository();
      vitalsRepo = MemoryVitalsRepository();
      reminderRepo = MemoryReminderRepository();
      activityRepo = MemoryActivityRepository();
      actionExecutor = ActionExecutor(
        patientRepository: patientRepo,
        vitalsRepository: vitalsRepo,
        reminderRepository: reminderRepo,
        activityRepository: activityRepo,
        isAuthorizedProvider: true,
      );
      orchestrator = ConversationOrchestrator(
        intentResolver: intentResolver,
        validator: validator,
        questionResolver: questionResolver,
        actionExecutor: actionExecutor,
      );
    });

    test('Natural clinical utterance extracts all slots and moves straight to confirmation review', () async {
      const voiceUtterance =
          "Add a new patient called Chika Okafor. She is 28 years old. She came in complaining of a headache that has lasted two days. Her blood pressure is 118 over 76 and her temperature is 37.2 degrees.";

      final state = await orchestrator.handleUserUtterance(
        voiceUtterance,
        ConversationWorkflowState.idle(),
        [],
      );

      // Intent identification
      expect(state.intent, equals(ConversationIntent.createPatient));

      // Information extraction
      expect(state.parameters['name'], equals('Chika Okafor'));
      expect(state.parameters['age'], equals(28));
      expect(state.parameters['gender'], equals('Female'));
      expect(state.parameters['complaint'], contains('headache'));
      expect(state.parameters['systolic'], equals(118.0));
      expect(state.parameters['diastolic'], equals(76.0));
      expect(state.parameters['bodyTemperature'], equals(37.2));

      // Must move straight to review confirmation without asking redundant questions!
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));

      // Provider confirms
      final confirmedState = await orchestrator.handleConfirmation(state);
      expect(confirmedState.status, equals(WorkflowStatus.completed));

      // Patient saved in repository
      expect(patientRepo.list.length, equals(1));
      expect(patientRepo.list.first.name, equals('Chika Okafor'));
      expect(patientRepo.list.first.notes, contains('headache'));

      // Initial vitals recorded in repository
      expect(vitalsRepo.vitals.length, equals(1));
      expect(vitalsRepo.vitals.first.systolic, equals(118.0));
      expect(vitalsRepo.vitals.first.diastolic, equals(76.0));
      expect(vitalsRepo.vitals.first.bodyTemperature, equals(37.2));
    });

    test('Step-by-step patient creation offers clean field continuation and confirmation', () async {
      // User says: "Create a patient named Amara Okonkwo"
      var state = await orchestrator.handleUserUtterance(
        "Create a patient named Amara Okonkwo",
        ConversationWorkflowState.idle(),
        [],
      );

      expect(state.intent, equals(ConversationIntent.createPatient));
      expect(state.parameters['name'], equals('Amara Okonkwo'));

      // Resolves follow-up options
      expect(state.currentQuestion?.targetField, equals('dateOfBirth'));

      // User provides DOB
      state = await orchestrator.handleOptionSelection(
        'dateOfBirth',
        DateTime(1995, 4, 15),
        state,
        [],
      );

      // Next optional details: phone
      expect(state.currentQuestion?.targetField, equals('phone'));
      // User skips phone
      state = await orchestrator.handleOptionSelection(
        'skip_phone',
        true,
        state,
        [],
      );

      // Next optional details: gender
      expect(state.currentQuestion?.targetField, equals('gender'));
      state = await orchestrator.handleOptionSelection(
        'gender',
        'Female',
        state,
        [],
      );

      // Ready for confirmation
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));

      final confirmed = await orchestrator.handleConfirmation(state);
      expect(confirmed.status, equals(WorkflowStatus.completed));
      expect(patientRepo.list.any((p) => p.name == 'Amara Okonkwo'), isTrue);
    });
  });

  group('Priority 3: Patient Switching & Independent Conversations', () {
    late IntentResolver intentResolver;
    late WorkflowValidator validator;
    late FollowUpQuestionResolver questionResolver;
    late MemoryPatientRepository patientRepo;
    late MemoryVitalsRepository vitalsRepo;
    late MemoryReminderRepository reminderRepo;
    late MemoryActivityRepository activityRepo;
    late ActionExecutor actionExecutor;
    late ConversationOrchestrator orchestrator;
    late List<PatientModel> existingPatients;

    setUp(() {
      intentResolver = const IntentResolver();
      validator = const WorkflowValidator();
      questionResolver = const FollowUpQuestionResolver();
      patientRepo = MemoryPatientRepository();
      vitalsRepo = MemoryVitalsRepository();
      reminderRepo = MemoryReminderRepository();
      activityRepo = MemoryActivityRepository();

      existingPatients = [
        PatientModel()
          ..id = 1
          ..name = 'Chika Okafor',
        PatientModel()
          ..id = 2
          ..name = 'John Doe',
      ];
      patientRepo.list.addAll(existingPatients);

      actionExecutor = ActionExecutor(
        patientRepository: patientRepo,
        vitalsRepository: vitalsRepo,
        reminderRepository: reminderRepo,
        activityRepository: activityRepo,
        isAuthorizedProvider: true,
      );
      orchestrator = ConversationOrchestrator(
        intentResolver: intentResolver,
        validator: validator,
        questionResolver: questionResolver,
        actionExecutor: actionExecutor,
      );
    });

    test('Recognizes "Switch to Chika" and switches active patient context', () async {
      final state = await orchestrator.handleUserUtterance(
        "Switch to Chika",
        ConversationWorkflowState.idle(),
        existingPatients,
      );

      expect(state.intent, equals(ConversationIntent.switchPatient));
      expect(state.activePatient?.name, equals('Chika Okafor'));
      expect(state.status, equals(WorkflowStatus.completed));
    });

    test('Recognizes "Let\'s work on John\'s record" and switches active patient context', () async {
      final state = await orchestrator.handleUserUtterance(
        "Let's work on John's record",
        ConversationWorkflowState.idle(),
        existingPatients,
      );

      expect(state.intent, equals(ConversationIntent.switchPatient));
      expect(state.activePatient?.name, equals('John Doe'));
      expect(state.status, equals(WorkflowStatus.completed));
    });

    test('Switching patients provides disambiguation when multiple patients match', () async {
      final multiPatients = [
        PatientModel()
          ..id = 1
          ..name = 'Chika Okafor',
        PatientModel()
          ..id = 2
          ..name = 'Chika Eze',
      ];
      patientRepo.list.clear();
      patientRepo.list.addAll(multiPatients);

      final state = await orchestrator.handleUserUtterance(
        "Switch to Chika",
        ConversationWorkflowState.idle(),
        multiPatients,
      );

      expect(state.intent, equals(ConversationIntent.switchPatient));
      expect(state.status, equals(WorkflowStatus.awaitingSelection));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.patientSelection));
    });

    test('Exact match "Patient A" does NOT match "New Patient" due to common word stopword filtering', () async {
      final patientsWithCommonWord = [
        PatientModel()
          ..id = 10
          ..remoteId = 'uuid-patient-a'
          ..name = 'Patient A',
        PatientModel()
          ..id = 11
          ..remoteId = 'uuid-new-patient'
          ..name = 'New Patient',
      ];
      patientRepo.list.clear();
      patientRepo.list.addAll(patientsWithCommonWord);

      // 1. "switch to patient a" should match Patient A exclusively without ambiguity
      final switchState = await orchestrator.handleUserUtterance(
        "switch to patient a",
        ConversationWorkflowState.idle(),
        patientsWithCommonWord,
      );

      expect(switchState.intent, equals(ConversationIntent.switchPatient));
      expect(switchState.activePatient?.name, equals('Patient A'));
      expect(switchState.status, equals(WorkflowStatus.completed));
      expect(switchState.candidatePatients, isEmpty);

      // 2. "Summarise Patient A's patient history." with Patient A active should execute directly
      final historyState = await orchestrator.handleUserUtterance(
        "Summarise Patient A's patient history.",
        ConversationWorkflowState.idle().copyWith(activePatient: patientsWithCommonWord.first),
        patientsWithCommonWord,
      );

      expect(historyState.intent, equals(ConversationIntent.queryPatientHistory));
      expect(historyState.status, equals(WorkflowStatus.completed));
      expect(historyState.activePatient?.name, equals('Patient A'));
      expect(historyState.candidatePatients, isEmpty);
    });

    test('Interactive patient selection understands "switch to patient a" and selects Patient A', () async {
      final patients = [
        PatientModel()
          ..id = 10
          ..remoteId = 'uuid-patient-a'
          ..name = 'Patient A',
        PatientModel()
          ..id = 11
          ..remoteId = 'uuid-new-patient'
          ..name = 'New Patient',
      ];
      patientRepo.list.clear();
      patientRepo.list.addAll(patients);

      // Start in awaitingSelection with disambiguation
      final initialQuestionState = ConversationWorkflowState.idle().copyWith(
        status: WorkflowStatus.awaitingSelection,
        intent: ConversationIntent.switchPatient,
        candidatePatients: patients,
        currentQuestion: questionResolver.resolveNextQuestion(
          ConversationWorkflowState.idle().copyWith(
            status: WorkflowStatus.awaitingSelection,
            intent: ConversationIntent.switchPatient,
            candidatePatients: patients,
          ),
          patients,
        ),
      );

      // User responds by typing or saying "switch to patient a"
      final nextState = await orchestrator.handleUserUtterance(
        "switch to patient a",
        initialQuestionState,
        patients,
      );

      expect(nextState.status, equals(WorkflowStatus.completed));
      expect(nextState.activePatient?.name, equals('Patient A'));
      expect(nextState.validationErrors, isEmpty);
    });
  });
}
