import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/conversation/models/conversation_intent.dart';
import 'package:vitalai/core/conversation/models/conversation_workflow_state.dart';
import 'package:vitalai/core/conversation/services/action_executor.dart';
import 'package:vitalai/core/genui/genui.dart';
import 'package:vitalai/core/services/ai_service.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intelligent GenUI System - 6 Conversational Scenarios', () {
    const engine = GenUiEngine();

    final johnDoe = PatientModel()
      ..id = 2
      ..remoteId = 'PAT-002'
      ..name = 'John Doe'
      ..dateOfBirth = DateTime(1982, 7, 10)
      ..gender = 'Male'
      ..emergencyContact = '+1 555 019 2831'
      ..medicalConditions = ['Hypertension']
      ..height = 178.0
      ..weight = 82.0
      ..isSynced = true
      ..updatedAt = DateTime.now();

    final johnSmith = PatientModel()
      ..id = 3
      ..remoteId = 'PAT-003'
      ..name = 'John Smith'
      ..dateOfBirth = DateTime(1965, 11, 20)
      ..gender = 'Male'
      ..emergencyContact = '+1 555 019 4492'
      ..medicalConditions = ['Type 2 Diabetes']
      ..height = 172.0
      ..weight = 88.0
      ..isSynced = true
      ..updatedAt = DateTime.now();

    test(
      'Scenario 1: Patient creation extracts info, presents draft card and follow-up options',
      () {
        final response = engine.createPatientDraftResponse(
          name: 'Chika Okafor',
          age: '28',
          complaint: 'Headache',
          duration: '2 days',
          bloodPressure: '118/76',
        );

        expect(
          response.message,
          contains("I've extracted the information for Chika Okafor."),
        );
        expect(response.components.length, 2);

        // Verify editable patient card
        final patientCard = response.components.first;
        expect(patientCard.type, GenUiComponentTypes.editablePatientCard);
        expect(patientCard.data['name'], 'Chika Okafor');
        expect(patientCard.data['age'], '28');
        expect(patientCard.data['complaint'], 'Headache');
        expect(patientCard.data['duration'], '2 days');
        expect(patientCard.data['bloodPressure'], '118/76');

        // Verify follow-up question card
        final followUp = response.components[1];
        expect(followUp.type, GenUiComponentTypes.choiceCard);
        expect(followUp.data['title'], 'Would you like to add anything else?');
        final options = followUp.options.map((o) => o.label).toList();
        expect(options, contains('Add temperature'));
        expect(options, contains('Add medication history'));
        expect(options, contains('Add clinical notes'));
        expect(options, contains('Review and save'));

        // Verify provider does NOT get re-asked for name or age
        expect(options, isNot(contains('Add name')));
        expect(options, isNot(contains('Add age')));

        // Contextual suggestions
        expect(
          response.suggestions.any((s) => s.label == 'Edit details'),
          isTrue,
        );
        expect(
          response.suggestions.any((s) => s.label == 'Review and save'),
          isTrue,
        );
      },
    );

    test(
      'Scenario 2: Recording vitals generates pre-populated card, date/time, and post-save actions',
      () {
        final response = engine.createVitalsEntryResponse(
          patientName: 'Chika Okafor',
          patientId: 1,
          temperature: 37.2,
          pulse: 78,
        );

        expect(
          response.message,
          contains(
            "I found Chika Okafor's patient record and prepared the new readings.",
          ),
        );
        expect(response.components.length, 1);

        final vitalsCard = response.components.first;
        expect(vitalsCard.type, GenUiComponentTypes.vitalInputCard);
        expect(vitalsCard.data['temperature'], 37.2);
        expect(vitalsCard.data['pulse'], 78);
        expect(vitalsCard.data['timestamp'], isNotNull);

        // Verify actions include confirm and cancel
        expect(
          vitalsCard.actions.any((a) => a.type == GenUiActionType.confirmSave),
          isTrue,
        );
        expect(
          vitalsCard.actions.any(
            (a) => a.type == GenUiActionType.cancelWorkflow,
          ),
          isTrue,
        );

        // After save is committed by repository
        final postSaveResponse = engine.createVitalsSavedResponse(
          patientName: 'Chika Okafor',
          patientId: 1,
          summary: 'Temperature: 37.2°C, Pulse: 78 bpm',
        );

        expect(
          postSaveResponse.components.first.type,
          GenUiComponentTypes.successCard,
        );
        final nextActions = postSaveResponse.components.first.actions
            .map((a) => a.label)
            .toList();
        expect(nextActions, contains('View updated vitals'));
        expect(nextActions, contains('View patient profile'));
        expect(nextActions, contains('Record more vitals'));
      },
    );

    test(
      'Scenario 3: Patient question retrieves real readings and provides contextual suggestions',
      () {
        final response = engine.createLatestVitalsResponse(
          patientName: 'Chika Okafor',
          patientId: 1,
          latestVitals: {
            'Blood Pressure': '118/76',
            'Pulse': '74 bpm',
            'Temperature': '36.8°C',
          },
          historicalBpPoints: [122.0, 120.0, 118.0, 118.0],
        );

        expect(
          response.message,
          contains("latest blood pressure reading is 118/76"),
        );
        expect(response.components.first.type, GenUiComponentTypes.chartCard);
        expect(response.components.first.data['dataPoints'], isNotEmpty);

        // Verify suggestions: Compare readings, View complete history, Record new vitals
        final suggestionLabels = response.suggestions
            .map((s) => s.label)
            .toList();
        expect(suggestionLabels, contains('Compare readings'));
        expect(suggestionLabels, contains('View complete history'));
        expect(suggestionLabels, contains('Record new vitals'));
      },
    );

    test(
      'Scenario 4: Patient history produces structured summary distinguishing facts from AI summary',
      () {
        final response = engine.createPatientHistoryResponse(
          patientName: 'Chika Okafor',
          patientId: 1,
          age: '28',
          latestVitals: {'Blood Pressure': '118/76 mmHg', 'Pulse': '74 bpm'},
          medicalHistory: ['Migraine with aura'],
          medications: ['Sumatriptan 50mg PRN'],
          clinicalNotes: ['Routine outpatient follow-up. Vital signs stable.'],
          missingInfo: ['Family medical history'],
        );

        expect(
          response.components.first.type,
          GenUiComponentTypes.clinicalSummaryCard,
        );
        final cardData = response.components.first.data;
        expect(cardData['medicalHistory'], contains('Migraine with aura'));
        expect(cardData['medications'], contains('Sumatriptan 50mg PRN'));
        expect(cardData['missingInfo'], contains('Family medical history'));

        // Contextual suggestions: View detailed notes, View vital trends, Ask another question
        final suggestionLabels = response.suggestions
            .map((s) => s.label)
            .toList();
        expect(suggestionLabels, contains('View detailed notes'));
        expect(suggestionLabels, contains('View vital trends'));
        expect(suggestionLabels, contains('Ask another question'));
      },
    );

    test(
      'Scenario 5: Ambiguous patient query presents selection cards without disclosing details',
      () {
        final response = engine.createPatientDisambiguationResponse(
          queryName: 'John',
          matchingPatients: [johnDoe, johnSmith],
        );

        expect(response.message, equals('Which patient do you mean?'));
        expect(response.components.first.type, GenUiComponentTypes.patientCard);

        final options = response.components.first.options;
        expect(options.length, 2);
        expect(options[0].label, 'John Doe');
        expect(options[1].label, 'John Smith');

        // Does not disclose sensitive vitals before selection
        expect(
          response.components.first.data.containsKey('bloodPressure'),
          isFalse,
        );
      },
    );

    test(
      'Scenario 6: Incomplete request asks for missing blood pressure and preserves patient context',
      () {
        final response = engine.createIncompleteVitalsResponse(
          patientName: 'Chika Okafor',
          patientId: 1,
        );

        expect(
          response.message,
          contains('What is the blood pressure reading?'),
        );
        expect(
          response.components.first.type,
          GenUiComponentTypes.vitalInputCard,
        );
        expect(response.context['patientId'], 1);
        expect(response.context['patientName'], 'Chika Okafor');
      },
    );
  });

  group('Context-Aware Suggestion Engine Tests', () {
    const service = SuggestionService();

    test('Limits suggestions to maximum 3-4 primary actions', () {
      final suggestions = service.resolveSuggestions(
        intent: 'create_patient',
        workflowStatus: 'completed',
        patientName: 'Chika',
      );
      expect(suggestions.length, inInclusiveRange(1, 4));
    });

    test('Dynamically adapts suggestions based on situation', () {
      final vitalsSuggestions = service.resolveSuggestions(
        intent: 'record_vitals',
        workflowStatus: 'completed',
        patientName: 'Chika',
      );
      expect(
        vitalsSuggestions.any(
          (s) => s.label.contains('View') || s.label.contains('trends'),
        ),
        isTrue,
      );

      final chartSuggestions = service.resolveSuggestions(
        intent: 'compare_vitals',
        workflowStatus: 'active',
        isChartDisplayed: true,
      );
      expect(
        chartSuggestions.any((s) => s.label == 'Change date range'),
        isTrue,
      );
      expect(
        chartSuggestions.any((s) => s.label == 'Compare readings'),
        isTrue,
      );
    });
  });

  group('GenUI Schema Validation & Safety Boundaries', () {
    const validator = GenUiValidator();

    test('Rejects systolic reading less than or equal to diastolic', () {
      const invalidBpCard = GenUiComponent(
        id: 'bp_test_1',
        type: GenUiComponentTypes.vitalInputCard,
        data: {'systolic': 80, 'diastolic': 120},
      );

      final result = validator.validateComponent(invalidBpCard);
      expect(result.isValid, isFalse);
      expect(
        result.errors.first,
        contains('must be strictly greater than diastolic'),
      );
    });

    test('Rejects physiologically implausible systolic (>300 mmHg)', () {
      const invalidBpCard = GenUiComponent(
        id: 'bp_test_2',
        type: GenUiComponentTypes.vitalInputCard,
        data: {'systolic': 450, 'diastolic': 80},
      );

      final result = validator.validateComponent(invalidBpCard);
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('outside physiological boundaries'));
    });

    test('Rejects negative patient age', () {
      const invalidAgeCard = GenUiComponent(
        id: 'patient_test_1',
        type: GenUiComponentTypes.editablePatientCard,
        data: {'name': 'Baby Doe', 'age': -5},
      );

      final result = validator.validateComponent(invalidAgeCard);
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Must be between 0 and 130 years'));
    });

    test('Rejects unknown component types gracefully', () {
      const unknownCard = GenUiComponent(
        id: 'malicious_code_card',
        type: 'arbitrary_eval_widget',
        data: {'code': 'import "dart:io"; exit(1);'},
      );

      final result = validator.validateComponent(unknownCard);
      expect(result.isValid, isFalse);
      expect(
        result.errors.first,
        contains('Unrecognized GenUI component type'),
      );
    });

    test('Parses raw AI markdown code fences and cleans tags', () {
      const aiResponse = '''
I have checked the readings for Chika.

<gen_ui>
{
  "type": "chart_card",
  "title": "Chika's BP Trend",
  "data": {
    "metric": "Blood Pressure",
    "dataPoints": [120, 118, 122]
  }
}
</gen_ui>

Please monitor daily.
''';

      final response = GenUiResponse.fromRawAiText(aiResponse);
      expect(
        response.message,
        contains('I have checked the readings for Chika.'),
      );
      expect(response.message, contains('Please monitor daily.'));
      expect(response.message, isNot(contains('<gen_ui>')));
      expect(response.components.length, 1);
      expect(response.components.first.type, GenUiComponentTypes.chartCard);
    });
  });

  group('GenUI Widget Rendering Tests (All 10 Components)', () {
    testWidgets('Renders SuggestionCard and triggers onActionSelected', (
      tester,
    ) async {
      GenUiAction? tappedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              component: const GenUiComponent(
                id: 'sugg_1',
                type: GenUiComponentTypes.suggestionCard,
                actions: [
                  GenUiAction(
                    id: 'act_1',
                    type: GenUiActionType.compareVitals,
                    label: 'Compare readings',
                  ),
                  GenUiAction(
                    id: 'act_2',
                    type: GenUiActionType.viewVitalHistory,
                    label: 'View history',
                  ),
                ],
              ),
              onActionSelected: (a) => tappedAction = a,
            ),
          ),
        ),
      );

      expect(find.text('Compare readings'), findsOneWidget);
      expect(find.text('View history'), findsOneWidget);

      await tester.tap(find.text('Compare readings'));
      await tester.pump();

      expect(tappedAction, isNotNull);
      expect(tappedAction!.type, GenUiActionType.compareVitals);
    });

    testWidgets(
      'Renders ChoiceCard in single-choice mode and triggers onOptionSelected',
      (tester) async {
        GenUiOption? selectedOption;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChoiceCard(
                component: const GenUiComponent(
                  id: 'choice_1',
                  type: GenUiComponentTypes.singleChoice,
                  data: {'title': 'Which vitals would you like to record?'},
                  options: [
                    GenUiOption(id: 'all', label: 'All vitals', value: 'all'),
                    GenUiOption(id: 'bp', label: 'Blood pressure', value: 'bp'),
                  ],
                ),
                onOptionSelected: (o) => selectedOption = o,
              ),
            ),
          ),
        );

        expect(
          find.text('Which vitals would you like to record?'),
          findsOneWidget,
        );
        expect(find.text('All vitals'), findsOneWidget);

        await tester.tap(find.text('Blood pressure'));
        await tester.pump();

        expect(selectedOption, isNotNull);
        expect(selectedOption!.value, 'bp');
      },
    );

    testWidgets(
      'Renders ChoiceCard in multiple-choice mode with Continue button',
      (tester) async {
        List<GenUiOption>? submittedOptions;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChoiceCard(
                isMultiple: true,
                component: const GenUiComponent(
                  id: 'choice_multi',
                  type: GenUiComponentTypes.multipleChoice,
                  data: {'title': 'Select summary sections:'},
                  options: [
                    GenUiOption(
                      id: 'vitals',
                      label: 'Vital signs',
                      value: 'vitals',
                    ),
                    GenUiOption(
                      id: 'notes',
                      label: 'Clinical notes',
                      value: 'notes',
                    ),
                  ],
                ),
                onMultiOptionSubmitted: (opts) => submittedOptions = opts,
              ),
            ),
          ),
        );

        expect(find.text('Select summary sections:'), findsOneWidget);
        await tester.tap(find.text('Vital signs'));
        await tester.pump();

        expect(find.text('Continue (1 selected)'), findsOneWidget);
        await tester.tap(find.text('Continue (1 selected)'));
        await tester.pump();

        expect(submittedOptions, isNotNull);
        expect(submittedOptions!.first.value, 'vitals');
      },
    );

    testWidgets(
      'Renders FollowUpCard with text input, quick chips, and submit',
      (tester) async {
        Map<String, dynamic>? submittedAnswer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FollowUpCard(
                component: const GenUiComponent(
                  id: 'followup_1',
                  type: GenUiComponentTypes.followUpCard,
                  data: {
                    'prompt': 'What is the duration of the headache?',
                    'targetField': 'duration',
                    'choices': ['1 day', '2 days', '1 week'],
                  },
                ),
                onAnswerSubmitted: (ans) => submittedAnswer = ans,
              ),
            ),
          ),
        );

        expect(
          find.text('What is the duration of the headache?'),
          findsOneWidget,
        );
        expect(find.text('2 days'), findsOneWidget);

        // Tap quick choice chip
        await tester.tap(find.text('2 days'));
        await tester.pump();

        // Submit via arrow button
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        expect(submittedAnswer, isNotNull);
        expect(submittedAnswer!['value'], '2 days');
      },
    );

    testWidgets(
      'Renders PatientCard with multiple patients and triggers selection',
      (tester) async {
        GenUiOption? selectedPatient;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PatientCard(
                component: const GenUiComponent(
                  id: 'patient_select_1',
                  type: GenUiComponentTypes.patientCard,
                  data: {'title': 'Which patient do you mean?'},
                  options: [
                    GenUiOption(
                      id: '1',
                      label: 'John Doe',
                      value: 1,
                      metadata: {'id': 1, 'age': 44},
                    ),
                    GenUiOption(
                      id: '2',
                      label: 'John Smith',
                      value: 2,
                      metadata: {'id': 2, 'age': 61},
                    ),
                  ],
                ),
                onPatientSelected: (p) => selectedPatient = p,
              ),
            ),
          ),
        );

        expect(find.text('Which patient do you mean?'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('John Smith'), findsOneWidget);

        await tester.tap(find.text('John Doe'));
        await tester.pump();

        expect(selectedPatient, isNotNull);
        expect(selectedPatient!.value, 1);
      },
    );

    testWidgets(
      'Renders EditablePatientCard with fields and Not provided for missing values',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditablePatientCard(
                component: const GenUiComponent(
                  id: 'edit_patient_1',
                  type: GenUiComponentTypes.editablePatientCard,
                  data: {
                    'name': 'Chika Okafor',
                    'age': '28',
                    'complaint': 'Headache',
                    'duration': '2 days',
                    // bloodPressure is intentionally omitted
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('Chika Okafor'), findsOneWidget);
        expect(find.text('28 years'), findsOneWidget);
        expect(find.text('Headache'), findsOneWidget);
        expect(
          find.text('Not provided'),
          findsOneWidget,
        ); // For missing blood pressure
      },
    );

    testWidgets(
      'Renders VitalInputCard and validates blood pressure before saving',
      (tester) async {
        Map<String, dynamic>? savedVitals;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: VitalInputCard(
                  component: const GenUiComponent(
                    id: 'vital_input_1',
                    type: GenUiComponentTypes.vitalInputCard,
                    data: {
                      'patientName': 'Chika Okafor',
                      'systolic': 118,
                      'diastolic': 76,
                      'pulse': 74,
                    },
                  ),
                  onSaveVitals: (v) => savedVitals = v,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Record Vitals for Chika Okafor'), findsOneWidget);
        expect(find.text('118'), findsOneWidget);
        expect(find.text('76'), findsOneWidget);

        await tester.tap(find.text('Review & Save Vitals'));
        await tester.pump();

        expect(savedVitals, isNotNull);
        expect(savedVitals!['systolic'], 118.0);
        expect(savedVitals!['diastolic'], 76.0);
      },
    );

    testWidgets(
      'Renders ChartCard with readings or explains insufficient data notice',
      (tester) async {
        // 1. With readings
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChartCard(
                component: const GenUiComponent(
                  id: 'chart_1',
                  type: GenUiComponentTypes.chartCard,
                  data: {
                    'title': 'BP Trend',
                    'metric': 'Blood Pressure',
                    'dataPoints': [120.0, 118.0, 122.0],
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('BP Trend'), findsOneWidget);
        expect(find.text('7D'), findsOneWidget);
        expect(find.text('Compare readings'), findsOneWidget);

        // 2. Insufficient data limitation notice
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChartCard(
                component: const GenUiComponent(
                  id: 'chart_empty',
                  type: GenUiComponentTypes.chartCard,
                  data: {
                    'title': 'Empty Trend',
                    'metric': 'Heart Rate',
                    'dataPoints': [72.0], // Only 1 point
                  },
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Insufficient historical data for Heart Rate.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Renders ClinicalSummaryCard with verified record badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSummaryCard(
              component: const GenUiComponent(
                id: 'summary_1',
                type: GenUiComponentTypes.clinicalSummaryCard,
                data: {
                  'patientName': 'Chika Okafor',
                  'age': '28',
                  'latestVitals': {'BP': '118/76 mmHg'},
                  'medicalHistory': ['Migraine with aura'],
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clinical Summary: Chika Okafor'), findsOneWidget);
      expect(find.text('Verified Record'), findsOneWidget);
      expect(find.text('• Migraine with aura'), findsOneWidget);
      expect(find.text('View full history'), findsOneWidget);
    });

    testWidgets('Renders ConfirmationCard and SuccessCard appropriately', (
      tester,
    ) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ConfirmationCard(
                  component: const GenUiComponent(
                    id: 'conf_1',
                    type: GenUiComponentTypes.confirmationCard,
                    data: {
                      'title': 'Confirm Registration',
                      'summary': 'Creating record for Chika Okafor (28 yrs)',
                    },
                  ),
                  onConfirm: () => confirmed = true,
                ),
                const SuccessCard(
                  component: GenUiComponent(
                    id: 'succ_1',
                    type: GenUiComponentTypes.successCard,
                    data: {'message': 'Patient successfully saved.'},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Confirm Registration'), findsOneWidget);
      expect(find.text('Patient successfully saved.'), findsOneWidget);

      await tester.tap(find.text('Confirm & Save'));
      await tester.pump();

      expect(confirmed, isTrue);
    });
  });

  group('General Query & ActionExecutor Execution', () {
    test('ActionExecutor handles ConversationIntent.generalQuery successfully', () async {
      final samplePatient = PatientModel()
        ..id = 1
        ..name = 'Chika Okafor'
        ..remoteId = 'P1'
        ..dateOfBirth = DateTime(1995, 1, 1)
        ..gender = 'Female'
        ..emergencyContact = '123'
        ..updatedAt = DateTime.now()
        ..isSynced = true;

      final fakePatientRepo = _MockPatientRepository([samplePatient]);
      final fakeVitalsRepo = _MockVitalsRepository();
      final fakeReminderRepo = _MockReminderRepository();

      final executor = ActionExecutor(
        patientRepository: fakePatientRepo,
        vitalsRepository: fakeVitalsRepo,
        reminderRepository: fakeReminderRepo,
      );

      // 1. General clinical question
      final state = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.generalQuery,
        lastUserUtterance: 'What is normal blood pressure?',
      );

      final result = await executor.executeWorkflowAction(state);
      expect(result.isSuccess, isTrue);
      expect(result.actionType, AppActionType.generalQuery);
      expect(result.summaryText, contains('120'));

      // 2. Friendly greeting
      final greetingState = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.generalQuery,
        lastUserUtterance: 'Hello',
      );

      final greetingResult = await executor.executeWorkflowAction(greetingState);
      expect(greetingResult.isSuccess, isTrue);
      expect(greetingResult.actionType, AppActionType.generalQuery);
      expect(greetingResult.summaryText, contains('VitalAI'));

      // 3. High blood pressure patients query
      final bpQueryState = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.generalQuery,
        lastUserUtterance: 'Show me my patients with high blood pressure',
      );

      final bpResult = await executor.executeWorkflowAction(bpQueryState);
      expect(bpResult.isSuccess, isTrue);
      expect(bpResult.actionType, AppActionType.generalQuery);

      // 4. Enable AI consent conversational utterance
      final consentState = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.generalQuery,
        lastUserUtterance: 'Please enable AI sharing',
      );
      final consentResult = await executor.executeWorkflowAction(consentState);
      expect(consentResult.isSuccess, isTrue);
      expect(consentResult.summaryText, contains('AI Data Sharing has been successfully enabled'));

      // 5. Normal vital ranges inquiry does not return "Consent Required" dead-end
      final vitalsQueryState = ConversationWorkflowState.idle().copyWith(
        intent: ConversationIntent.generalQuery,
        lastUserUtterance: 'What are normal vital signs ranges?',
      );
      final vitalsResult = await executor.executeWorkflowAction(vitalsQueryState);
      expect(vitalsResult.isSuccess, isTrue);
      expect(vitalsResult.summaryText, contains('Blood Pressure: <120/80 mmHg'));
      expect(vitalsResult.summaryText.toLowerCase(), isNot(contains('consent required')));
    });

    test('SuggestionService suggests Enable Live AI Assistant when hasAiConsent is false', () {
      const suggestionService = SuggestionService();
      final suggestionsWithoutConsent = suggestionService.resolveSuggestions(
        intent: 'general_query',
        workflowStatus: 'completed',
        hasAiConsent: false,
      );

      expect(
        suggestionsWithoutConsent.any((a) => a.id == 'enable_ai_sharing'),
        isTrue,
      );

      final suggestionsWithConsent = suggestionService.resolveSuggestions(
        intent: 'general_query',
        workflowStatus: 'completed',
        hasAiConsent: true,
      );

      expect(
        suggestionsWithConsent.any((a) => a.id == 'enable_ai_sharing'),
        isFalse,
      );
    });

    test('AiService emergency check is never blocked by consent status', () async {
      final aiService = AiService(null);
      final emergencyResponse = await aiService.askAssistant('I have severe chest pain and cannot breathe');
      expect(emergencyResponse, contains('EMERGENCY MEDICAL NOTICE'));
      expect(emergencyResponse, contains('911'));
      expect(emergencyResponse.toLowerCase(), isNot(contains('consent required')));
    });
  });
}

class _MockPatientRepository implements PatientRepository {
  final List<PatientModel> list;
  _MockPatientRepository([this.list = const []]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PatientModel>> getPatients() async => list;
  @override
  Future<PatientModel?> getPatientById(int id) async => list.isEmpty ? null : list.first;
}

class _MockVitalsRepository implements VitalsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<VitalRecord>> getVitals(int patientId) async => [];
}

class _MockReminderRepository implements ReminderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
