import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/conversation/bloc/conversation_workflow_bloc.dart';
import 'package:vitalai/core/conversation/bloc/conversation_workflow_event.dart';
import 'package:vitalai/core/conversation/models/conversation_intent.dart';
import 'package:vitalai/core/conversation/models/conversation_workflow_state.dart';
import 'package:vitalai/core/conversation/models/follow_up_question.dart';
import 'package:vitalai/core/conversation/models/genui_question_type.dart';
import 'package:vitalai/core/conversation/models/workflow_status.dart';
import 'package:vitalai/core/conversation/services/action_executor.dart';
import 'package:vitalai/core/conversation/services/conversation_orchestrator.dart';
import 'package:vitalai/core/conversation/services/follow_up_question_resolver.dart';
import 'package:vitalai/core/conversation/services/intent_resolver.dart';
import 'package:vitalai/core/conversation/services/workflow_validator.dart';
import 'package:vitalai/core/conversation/widgets/adaptive_genui_follow_up_card.dart';
import 'package:vitalai/features/activity/data/models/activity_item.dart';
import 'package:vitalai/features/activity/domain/repositories/activity_repository.dart';
import 'package:vitalai/features/patients/data/models/clinical_note.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/reminders/data/models/reminder_model.dart';
import 'package:vitalai/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';

// --- FAKE REPOSITORIES FOR ISOLATED ENGINE TESTING ---

class TestPatientRepository implements PatientRepository {
  final List<PatientModel> storage = [];
  bool shouldFail = false;

  TestPatientRepository([List<PatientModel>? initial]) {
    if (initial != null) storage.addAll(initial);
  }

  @override
  Future<List<PatientModel>> getPatients() async => List.unmodifiable(storage);

  @override
  Future<PatientModel?> getPatientById(int id) async {
    try {
      return storage.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PatientModel?> getPatientByRemoteId(String remoteId) async {
    try {
      return storage.firstWhere((p) => p.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePatient(PatientModel patient) async {
    if (shouldFail) throw Exception('Simulated database write error');
    if (patient.id == 0) {
      patient.id = storage.length + 1;
      storage.add(patient);
    } else {
      final idx = storage.indexWhere((p) => p.id == patient.id);
      if (idx != -1) {
        storage[idx] = patient;
      } else {
        storage.add(patient);
      }
    }
  }

  @override
  Future<void> deletePatient(int localId, String remoteId) async {
    storage.removeWhere((p) => p.id == localId);
  }

  @override
  Future<void> syncPatients() async {}

  final Map<int, List<ClinicalNote>> _notesStorage = {};

  @override
  Future<List<ClinicalNote>> getClinicalNotes(int patientId) async =>
      _notesStorage[patientId] ?? [];

  @override
  Future<void> saveClinicalNote(ClinicalNote note) async {
    if (shouldFail) throw Exception('Simulated clinical note save timeout');
    _notesStorage.putIfAbsent(note.patientId, () => []).add(note);
  }
}

class TestVitalsRepository implements VitalsRepository {
  final List<VitalRecord> storage = [];
  bool shouldFail = false;

  TestVitalsRepository([List<VitalRecord>? initial]) {
    if (initial != null) storage.addAll(initial);
  }

  @override
  Future<List<VitalRecord>> getVitals(int patientId) async =>
      storage.where((v) => v.patientId == patientId).toList();

  @override
  Future<List<VitalRecord>> getFilteredVitals({
    required int patientId,
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    bool? abnormalOnly,
  }) async {
    return storage.where((v) => v.patientId == patientId).toList();
  }

  @override
  Future<void> saveVitalRecord(VitalRecord record) async {
    if (shouldFail) throw Exception('Simulated vitals table lock failure');
    if (record.id == 0) record.id = storage.length + 1;
    storage.add(record);
  }

  @override
  Future<void> deleteVitalRecord(int localId, String remoteId) async {
    storage.removeWhere((v) => v.id == localId);
  }

  @override
  Future<void> syncVitals() async {}
}

class TestReminderRepository implements ReminderRepository {
  final List<ReminderModel> storage = [];

  @override
  Future<List<ReminderModel>> getReminders(int patientId) async =>
      storage.where((r) => r.patientId == patientId).toList();

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    storage.add(reminder);
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    final idx = storage.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) storage[idx] = reminder;
  }

  @override
  Future<void> deleteReminder(String id, int patientId) async {
    storage.removeWhere((r) => r.id == id && r.patientId == patientId);
  }

  @override
  Future<void> toggleReminderCompletion(String id, int patientId) async {
    final idx = storage.indexWhere((r) => r.id == id && r.patientId == patientId);
    if (idx != -1) {
      final cur = storage[idx];
      storage[idx] = cur.copyWith(isCompleted: !cur.isCompleted);
    }
  }
}

class TestActivityRepository implements ActivityRepository {
  final List<ActivityItem> logged = [];

  @override
  Future<List<ActivityItem>> getActivities({ActivityCategory category = ActivityCategory.all}) async =>
      logged;

  @override
  Future<void> logActivity(ActivityItem item) async {
    logged.add(item);
  }

  @override
  Future<void> clearActivities() async {
    logged.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestPatientRepository patientRepo;
  late TestVitalsRepository vitalsRepo;
  late TestReminderRepository reminderRepo;
  late TestActivityRepository activityRepo;

  late IntentResolver intentResolver;
  late WorkflowValidator validator;
  late FollowUpQuestionResolver questionResolver;
  late ActionExecutor actionExecutor;
  late ConversationOrchestrator orchestrator;

  late List<PatientModel> existingPatients;

  setUp(() {
    existingPatients = [
      PatientModel()
        ..id = 1
        ..remoteId = 'CV-10024'
        ..name = 'Chika Okafor'
        ..dateOfBirth = DateTime(1991, 5, 14)
        ..phone = '+2348031234567'
        ..gender = 'Female',
      PatientModel()
        ..id = 2
        ..remoteId = 'CV-10025'
        ..name = 'Emeka Nwosu'
        ..dateOfBirth = DateTime(1973, 8, 20)
        ..phone = '+2348029876543'
        ..gender = 'Male',
      PatientModel()
        ..id = 3
        ..remoteId = 'CV-10028'
        ..name = 'Ada Okafor' // Duplicate last name to test disambiguation!
        ..dateOfBirth = DateTime(1995, 2, 10)
        ..phone = '+2348099998888'
        ..gender = 'Female',
    ];

    patientRepo = TestPatientRepository(existingPatients);
    vitalsRepo = TestVitalsRepository();
    reminderRepo = TestReminderRepository();
    activityRepo = TestActivityRepository();

    intentResolver = const IntentResolver();
    validator = const WorkflowValidator();
    questionResolver = const FollowUpQuestionResolver();
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

  group('Universal Conversational Workflow - Comprehensive Engine Tests', () {
    // 1. Complete requests needing no clarification
    test('Requirement 4: Complete request extracts all fields and moves straight to confirmation card', () async {
      final utterance = "Record Chika's blood pressure as 118 over 76 from today's visit.";
      var state = ConversationWorkflowState.idle();

      state = await orchestrator.handleUserUtterance(utterance, state, existingPatients);

      expect(state.intent, equals(ConversationIntent.recordVitals));
      expect(state.activePatient?.name, equals('Chika Okafor'));
      expect(state.parameters['systolic'], equals(118.0));
      expect(state.parameters['diastolic'], equals(76.0));
      expect(state.parameters['date'], isNotNull);

      // Must move directly to awaitingConfirmation with confirmationCard rather than asking redundant questions!
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));
    });

    // 2. Requests with missing fields
    test('Requirement 2 & 3: Missing fields trigger focused follow-up question and appropriate GenUI', () async {
      // Step 1: User provides only systolic reading
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record Chika's BP 130", state, existingPatients);

      expect(state.intent, equals(ConversationIntent.recordVitals));
      expect(state.activePatient?.name, equals('Chika Okafor'));
      expect(state.parameters['systolic'], equals(130.0));
      expect(state.parameters['diastolic'], isNull);

      // Must ask for diastolic with numericInput
      expect(state.status, equals(WorkflowStatus.collectingInformation));
      expect(state.currentQuestion?.targetField, equals('diastolic'));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.numericInput));
      expect(state.currentQuestion?.unit, equals('mmHg'));

      // Step 2: User provides diastolic via interactive answer
      state = await orchestrator.handleOptionSelection('diastolic', 82.0, state, existingPatients);

      // All fields now complete; moves directly to confirmation card
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));
      expect(state.parameters['diastolic'], equals(82.0));
    });

    // 3. Ambiguous patient identities
    test('Requirement 2 & 4: Ambiguous patient name triggers patient selection GenUI', () async {
      // "Okafor" matches both "Chika Okafor" and "Ada Okafor"
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record blood pressure 120/80 for Okafor", state, existingPatients);

      expect(state.status, equals(WorkflowStatus.awaitingSelection));
      expect(state.candidatePatients.length, equals(2));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.patientSelection));

      // Provider selects Chika Okafor
      state = await orchestrator.handleOptionSelection('patientId', 1, state, existingPatients);

      expect(state.activePatient?.name, equals('Chika Okafor'));
      // Now unambiguous; proceeds to confirmation card
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));
    });

    // 4. Clinical validation rules & correction flow
    test('Requirement 6: Invalid systolic <= diastolic rejected by validator and corrected by user', () async {
      var state = ConversationWorkflowState.idle();
      // Systolic 70 is less than diastolic 120
      state = await orchestrator.handleUserUtterance("Record Chika's BP 70 over 120", state, existingPatients);

      expect(state.validationErrors.containsKey('systolic'), isTrue);
      expect(state.validationErrors['systolic'], contains('must be higher than diastolic'));

      // User corrects by speaking a valid reading
      state = await orchestrator.handleUserUtterance("I mean 125 over 80", state, existingPatients);

      expect(state.validationErrors.isEmpty, isTrue);
      expect(state.parameters['systolic'], equals(125.0));
      expect(state.parameters['diastolic'], equals(80.0));
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
    });

    // 5. Consequential write requires explicit confirmation
    test('Requirement 6: Consequential action cannot execute without confirmation', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record Chika's BP 120 over 80", state, existingPatients);

      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.isConfirmed, isFalse);

      // Attempting to execute unconfirmed state directly fails
      final unauthorizedResult = await actionExecutor.executeWorkflowAction(state);
      expect(unauthorizedResult.isSuccess, isFalse);
      expect(unauthorizedResult.errorMessage, contains('requires explicit confirmation'));

      // Provider confirms
      state = await orchestrator.handleConfirmation(state);

      expect(state.status, equals(WorkflowStatus.completed));
      expect(vitalsRepo.storage.length, equals(1));
      expect(vitalsRepo.storage.first.systolic, equals(120.0));
      expect(vitalsRepo.storage.first.diastolic, equals(80.0));

      // Audit logged
      expect(activityRepo.logged.length, equals(1));
      expect(activityRepo.logged.first.category, equals(ActivityCategory.vitals));
    });

    // 6. Skipping optional fields
    test('Requirement 4 & 8: Skipping optional fields advances workflow cleanly', () async {
      var state = ConversationWorkflowState.idle();
      // Start patient creation with only intent and name
      state = await orchestrator.handleUserUtterance("Create a patient named John Doe", state, existingPatients);

      expect(state.intent, equals(ConversationIntent.createPatient));
      expect(state.parameters['name'], equals('John Doe'));
      expect(state.currentQuestion?.targetField, equals('dateOfBirth'));
      expect(state.currentQuestion?.isOptional, isTrue);

      // Skip DOB
      state = await orchestrator.handleUserUtterance("skip", state, existingPatients);
      expect(state.parameters['skip_dateOfBirth'], isTrue);
      expect(state.currentQuestion?.targetField, equals('phone'));

      // Skip phone
      state = await orchestrator.handleUserUtterance("skip", state, existingPatients);
      expect(state.parameters['skip_phone'], isTrue);

      // Skip gender
      state = await orchestrator.handleUserUtterance("skip", state, existingPatients);

      // Ready for confirmation!
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));
    });

    // 7. Back and Cancel behavior
    test('Requirement 5 & 8: Cancel and Step-back behavior', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record Chika's BP 120 over 80", state, existingPatients);
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));

      // User says cancel
      state = await orchestrator.handleUserUtterance("cancel", state, existingPatients);
      expect(state.status, equals(WorkflowStatus.cancelled));

      // Fresh workflow
      var state2 = ConversationWorkflowState.idle();
      state2 = await orchestrator.handleUserUtterance("Record Chika's blood pressure", state2, existingPatients);
      state2 = await orchestrator.handleOptionSelection('systolic', 135.0, state2, existingPatients);
      expect(state2.parameters['systolic'], equals(135.0));

      // User steps back
      state2 = orchestrator.handleStepBack(state2);
      expect(state2.parameters.containsKey('systolic'), isFalse);
    });

    // 8. Clinical Notes workflow
    test('Requirement 2 & 3: Clinical Note drafting asks for missing details and renders preview card', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Draft a clinical note for Chika", state, existingPatients);

      expect(state.intent, equals(ConversationIntent.draftClinicalNote));
      expect(state.activePatient?.name, equals('Chika Okafor'));
      expect(state.currentQuestion?.targetField, equals('visitType'));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.singleChoice));

      // Select visit type
      state = await orchestrator.handleOptionSelection('visitType', 'SOAP Note', state, existingPatients);

      // Asks for note content
      expect(state.currentQuestion?.targetField, equals('content'));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.textInput));

      // Submit content
      state = await orchestrator.handleOptionSelection(
        'content',
        'Patient reports blood pressure is well controlled on Amlodipine.',
        state,
        existingPatients,
      );

      // Shows preview card
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.previewCard));

      // Confirm & Save
      state = await orchestrator.handleConfirmation(state);
      expect(state.status, equals(WorkflowStatus.completed));
      expect(patientRepo._notesStorage[1]?.length, equals(1));
    });

    // 9. Follow-up and Appointments workflow
    test('Requirement 2: Schedule appointment asks for title and time and confirms', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Schedule an appointment for Chika", state, existingPatients);

      expect(state.intent, equals(ConversationIntent.manageAppointments));
      expect(state.activePatient?.name, equals('Chika Okafor'));

      // Asks for purpose
      expect(state.currentQuestion?.targetField, equals('title'));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.singleChoice));

      state = await orchestrator.handleOptionSelection('title', 'Blood Pressure Check', state, existingPatients);

      // Asks for time
      expect(state.currentQuestion?.targetField, equals('time'));
      state = await orchestrator.handleOptionSelection('time', '10:30 AM', state, existingPatients);

      // Awaiting confirmation
      expect(state.status, equals(WorkflowStatus.awaitingConfirmation));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.confirmationCard));

      // Confirm
      state = await orchestrator.handleConfirmation(state);
      expect(state.status, equals(WorkflowStatus.completed));
      expect(reminderRepo.storage.length, equals(1));
      expect(reminderRepo.storage.first.title, equals('Blood Pressure Check'));
    });

    // 10. Patient History & Summaries workflow
    test('Requirement 2 & 3: History query offers multi-select categories and proceeds read-only', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Review medical history for Chika", state, existingPatients);

      expect(state.intent, equals(ConversationIntent.queryPatientHistory));
      expect(state.currentQuestion?.targetField, equals('categories'));
      expect(state.currentQuestion?.questionType, equals(GenUiQuestionType.multiSelect));

      // Select categories
      state = await orchestrator.handleOptionSelection('categories', ['vitals', 'notes'], state, existingPatients);

      // Read-only intent completes without unnecessary confirmation
      expect(state.status, equals(WorkflowStatus.completed));
    });

    // 11. Backend failure and retry
    test('Requirement 6 & 9: Backend failure transitions to failed state and allows retry', () async {
      vitalsRepo.shouldFail = true;

      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record Chika's BP 120/80", state, existingPatients);
      state = await orchestrator.handleConfirmation(state);

      expect(state.status, equals(WorkflowStatus.failed));
      expect(state.errorMessage, contains('Simulated vitals table lock failure'));

      // Fix failure and retry
      vitalsRepo.shouldFail = false;
      state = await orchestrator.handleConfirmation(state);

      expect(state.status, equals(WorkflowStatus.completed));
      expect(vitalsRepo.storage.length, equals(1));
    });

    // 12. Unauthorized access guard
    test('Requirement 6: Unauthorized provider blocked at execution boundary', () async {
      final unauthorizedExecutor = ActionExecutor(
        patientRepository: patientRepo,
        vitalsRepository: vitalsRepo,
        reminderRepository: reminderRepo,
        isAuthorizedProvider: false,
      );
      final unauthOrchestrator = ConversationOrchestrator(
        intentResolver: intentResolver,
        validator: validator,
        questionResolver: questionResolver,
        actionExecutor: unauthorizedExecutor,
      );

      var state = ConversationWorkflowState.idle();
      state = await unauthOrchestrator.handleUserUtterance("Record Chika's BP 120/80", state, existingPatients);
      state = await unauthOrchestrator.handleConfirmation(state);

      expect(state.status, equals(WorkflowStatus.failed));
      expect(state.errorMessage, contains('Unauthorized access'));
      expect(vitalsRepo.storage.isEmpty, isTrue);
    });

    // 13. Prevention of duplicate submissions
    test('Requirement 6: Double confirmation while isExecuting=true is ignored', () async {
      var state = ConversationWorkflowState.idle();
      state = await orchestrator.handleUserUtterance("Record Chika's BP 120/80", state, existingPatients);

      // Set isExecuting = true
      final executingState = state.copyWith(isExecuting: true);
      final resultState = await orchestrator.handleConfirmation(executingState);

      // Must not double submit
      expect(resultState, equals(executingState));
    });
  });

  group('ConversationWorkflowBloc Tests (BLoC State Machine)', () {
    test('ConversationWorkflowBloc transitions from idle to completed through events', () async {
      final bloc = ConversationWorkflowBloc(orchestrator: orchestrator);

      expect(bloc.state.status, equals(WorkflowStatus.idle));

      // 1. Submit utterance
      bloc.add(ConversationUtteranceSubmitted(
        "Record Chika's blood pressure 130",
        existingPatients: existingPatients,
      ));
      await pumpEventQueue();

      expect(bloc.state.status, equals(WorkflowStatus.collectingInformation));
      expect(bloc.state.parameters['systolic'], equals(130.0));

      // 2. Select diastolic
      bloc.add(ConversationOptionSelected(
        'diastolic',
        85.0,
        existingPatients: existingPatients,
      ));
      await pumpEventQueue();

      expect(bloc.state.status, equals(WorkflowStatus.awaitingConfirmation));

      // 3. Confirm
      bloc.add(const ConversationWorkflowConfirmed());
      await pumpEventQueue();

      expect(bloc.state.status, equals(WorkflowStatus.completed));
      expect(vitalsRepo.storage.length, equals(1));

      await bloc.close();
    });
  });

  group('AdaptiveGenUiFollowUpCard Widget Rendering Tests', () {
    testWidgets('Renders numeric input question with unit badge and triggers onAnswer', (tester) async {
      const question = FollowUpQuestion(
        id: 'test_numeric',
        targetField: 'systolic',
        promptText: 'What is the systolic reading (mmHg)?',
        questionType: GenUiQuestionType.numericInput,
        unit: 'mmHg',
        initialValue: 120,
      );

      dynamic answeredValue;
      final state = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.recordVitals,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveGenUiFollowUpCard(
              question: question,
              state: state,
              onAnswer: (val) => answeredValue = val,
              onConfirm: () {},
              onCancel: () {},
              onSkip: () {},
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('What is the systolic reading (mmHg)?'), findsOneWidget);
      expect(find.text('mmHg'), findsOneWidget);

      // Enter value and tap button
      await tester.enterText(find.byType(TextField), '128');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(answeredValue, equals(128.0));
    });

    testWidgets('Renders single choice options and triggers onAnswer when tapped', (tester) async {
      const question = FollowUpQuestion(
        id: 'test_choice',
        targetField: 'visitType',
        promptText: 'Select encounter type:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(label: 'General Consultation', value: 'General Consultation', isRecommended: true),
          FollowUpOption(label: 'Urgent Care', value: 'Urgent Care'),
        ],
      );

      dynamic selectedOption;
      final state = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.draftClinicalNote,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveGenUiFollowUpCard(
              question: question,
              state: state,
              onAnswer: (val) => selectedOption = val,
              onConfirm: () {},
              onCancel: () {},
              onSkip: () {},
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Select encounter type:'), findsOneWidget);
      expect(find.text('General Consultation'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);

      await tester.tap(find.text('General Consultation'));
      await tester.pump();

      expect(selectedOption, equals('General Consultation'));
    });

    testWidgets('Renders confirmation card with Confirm & Save button and triggers onConfirm', (tester) async {
      const question = FollowUpQuestion(
        id: 'test_confirm',
        targetField: 'confirmed',
        promptText: 'Ready to record 118/76 mmHg for Chika Okafor. Please confirm:',
        questionType: GenUiQuestionType.confirmationCard,
        metadata: {
          'systolic': 118,
          'diastolic': 76,
          'patientName': 'Chika Okafor',
        },
      );

      bool confirmed = false;
      final state = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.recordVitals,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveGenUiFollowUpCard(
              question: question,
              state: state,
              onAnswer: (_) {},
              onConfirm: () => confirmed = true,
              onCancel: () {},
              onSkip: () {},
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ready to Commit Record'), findsOneWidget);
      expect(find.text('Confirm & Save'), findsOneWidget);

      await tester.tap(find.text('Confirm & Save'));
      await tester.pump();

      expect(confirmed, isTrue);
    });
  });
}
