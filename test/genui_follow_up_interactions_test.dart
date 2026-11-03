import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/genui/genui_parser.dart';
import 'package:vitalai/core/genui/models/genui_component_model.dart';
import 'package:vitalai/core/services/ai_service.dart';
import 'package:vitalai/features/ai_assistant/data/models/chat_message.dart';
import 'package:vitalai/features/ai_assistant/data/models/health_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenUI Follow-Up Interactions - Model & Security Whitelist Tests', () {
    test('GenUiFollowUpAction parses all 4 conceptual action types accurately', () {
      // 1. FOLLOW_UP_QUESTION
      final action1 = GenUiFollowUpAction.fromJson({
        "type": "follow_up_question",
        "label": "Show my BP trend",
        "prompt": "Show me this patient's blood pressure trend.",
      });
      expect(action1.actionType, equals(GenUiActionType.followUpQuestion));
      expect(action1.isFollowUpQuestion, isTrue);
      expect(action1.label, equals("Show my BP trend"));
      expect(action1.effectivePrompt, equals("Show me this patient's blood pressure trend."));

      // 2. NAVIGATION_ACTION
      final action2 = GenUiFollowUpAction.fromJson({
        "type": "navigation",
        "label": "View BP history",
        "destination": "blood_pressure_history",
      });
      expect(action2.actionType, equals(GenUiActionType.navigation));
      expect(action2.isNavigation, isTrue);
      expect(action2.destination, equals("blood_pressure_history"));

      // 3. DATA_ACTION
      final action3 = GenUiFollowUpAction.fromJson({
        "type": "view_vital",
        "label": "View Blood Pressure",
        "vital": "blood_pressure",
      });
      expect(action3.actionType, equals(GenUiActionType.dataAction));
      expect(action3.isDataAction, isTrue);
      expect(action3.vital, equals("blood_pressure"));

      // 4. INFORMATION_EXPANSION
      final action4 = GenUiFollowUpAction.fromJson({
        "type": "information_expansion",
        "label": "Explain this further",
        "prompt": "Explain this in more detail.",
      });
      expect(action4.actionType, equals(GenUiActionType.informationExpansion));
      expect(action4.isInformationExpansion, isTrue);
      expect(action4.effectivePrompt, equals("Explain this in more detail."));
    });

    test('Security Whitelist: strictly blocks unauthorized arbitrary destinations', () {
      // Authorized routes
      expect(GenUiValidRoutes.isSafeDestination("blood_pressure_history"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("/charts"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("charts"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("/history"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("reminders"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("patients"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("settings"), isTrue);
      expect(GenUiValidRoutes.isSafeDestination("add_vital"), isTrue);

      // Unauthorized arbitrary destinations MUST BE REJECTED
      expect(GenUiValidRoutes.isSafeDestination("navigate_to_secret_screen"), isFalse);
      expect(GenUiValidRoutes.isSafeDestination("admin_shell"), isFalse);
      expect(GenUiValidRoutes.isSafeDestination("eval_javascript"), isFalse);
      expect(GenUiValidRoutes.isSafeDestination("external_url_hack"), isFalse);
      expect(GenUiValidRoutes.isSafeDestination(null), isFalse);
      expect(GenUiValidRoutes.isSafeDestination(""), isFalse);

      // Resolution mappings
      expect(GenUiValidRoutes.resolveRoute("blood_pressure_history"), equals('/history'));
      expect(GenUiValidRoutes.resolveRoute("charts"), equals('/charts'));
      expect(GenUiValidRoutes.resolveRoute("reminders"), equals('/reminders'));
    });

    test('Security Whitelist: strictly validates supported vital metrics', () {
      expect(GenUiValidRoutes.isSafeVital("blood_pressure"), isTrue);
      expect(GenUiValidRoutes.isSafeVital("glucose"), isTrue);
      expect(GenUiValidRoutes.isSafeVital("pulse"), isTrue);
      expect(GenUiValidRoutes.isSafeVital("spo2"), isTrue);
      expect(GenUiValidRoutes.isSafeVital("temperature"), isTrue);
      expect(GenUiValidRoutes.isSafeVital("weight"), isTrue);

      // Invalid or arbitrary metric
      expect(GenUiValidRoutes.isSafeVital("secret_crypto_token"), isFalse);
      expect(GenUiValidRoutes.isSafeVital("unknown_payload"), isFalse);
      expect(GenUiValidRoutes.isSafeVital(null), isFalse);
    });
  });

  group('GenUI Follow-Up Interactions - Parser & Component Tests', () {
    test('GenUiParser parses follow_up_suggestions component block correctly', () {
      const payload = '''
Your latest blood pressure is 135/88 mmHg (Stage 1 Hypertension).

```json
{
  "type": "follow_up_suggestions",
  "title": "Suggested Next Steps",
  "suggestions": [
    {
      "type": "follow_up_question",
      "label": "Show my BP trend",
      "prompt": "Show me this patient's blood pressure trend."
    },
    {
      "type": "follow_up_question",
      "label": "What can cause high BP?",
      "prompt": "What can cause high blood pressure?"
    },
    {
      "type": "follow_up_question",
      "label": "Explain systolic vs diastolic",
      "prompt": "Explain systolic vs diastolic pressure."
    },
    {
      "type": "navigation",
      "label": "View BP History",
      "destination": "blood_pressure_history"
    },
    {
      "type": "view_vital",
      "label": "View Blood Pressure",
      "vital": "blood_pressure"
    }
  ]
}
```
''';

      final components = GenUiParser.parseComponents(payload);
      expect(components.length, equals(1));
      expect(components.first, isA<GenUiFollowUpSuggestionsModel>());

      final model = components.first as GenUiFollowUpSuggestionsModel;
      expect(model.title, equals("Suggested Next Steps"));
      expect(model.suggestions.length, equals(5));
      expect(model.suggestions[0].label, equals("Show my BP trend"));
      expect(model.suggestions[1].label, equals("What can cause high BP?"));
      expect(model.suggestions[2].label, equals("Explain systolic vs diastolic"));
      expect(model.suggestions[3].destination, equals("blood_pressure_history"));
      expect(model.suggestions[4].vital, equals("blood_pressure"));

      final structured = GenUiParser.parseStructuredResponse(payload);
      expect(structured.followUps.length, equals(5));
      expect(structured.answer, contains("Stage 1 Hypertension"));
    });

    test('GenUiParser parses individual follow_up_question block', () {
      const payload = '''
```json
{
  "type": "follow_up_question",
  "label": "Explain this in more detail",
  "prompt": "Explain this in more detail."
}
```
''';
      final components = GenUiParser.parseComponents(payload);
      expect(components.length, equals(1));
      expect(components.first, isA<GenUiFollowUpActionModel>());
      final actionModel = components.first as GenUiFollowUpActionModel;
      expect(actionModel.action.effectivePrompt, equals("Explain this in more detail."));
    });
  });

  group('GenUI Follow-Up Interactions - Conversational Loop & Context Continuity', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService(null); // Offline deterministic clinical engine
    });

    const mockPatientA = HealthContext(
      patientId: 101,
      patientName: 'Sarah Connor',
      gender: 'Female',
      age: 42,
      medicalNotes: '',
      conditions: ['Hypertension'],
      allergies: [],
      medications: ['Lisinopril 10mg'],
      bpSystolicTrend: MetricTrend(average: 136, highest: 144, lowest: 128, direction: 'Elevated', totalReadings: 4),
      bpDiastolicTrend: MetricTrend(average: 86, highest: 90, lowest: 82, direction: 'Stable', totalReadings: 4),
      glucoseTrend: MetricTrend(average: 94, direction: 'Stable', totalReadings: 2),
      pulseTrend: MetricTrend(average: 72, direction: 'Stable', totalReadings: 4),
      spo2Trend: MetricTrend(average: 98, direction: 'Stable', totalReadings: 4),
      tempTrend: MetricTrend(average: 36.6, direction: 'Stable', totalReadings: 2),
      weightTrend: MetricTrend(average: 63.0, direction: 'Stable', totalReadings: 2),
      bmiTrend: MetricTrend(average: 22.5, direction: 'Stable', totalReadings: 2),
      recentSymptoms: [],
      totalVitalsCount: 4,
    );

    const mockPatientB = HealthContext(
      patientId: 202,
      patientName: 'John Connor',
      gender: 'Male',
      age: 28,
      medicalNotes: '',
      conditions: [],
      allergies: [],
      medications: [],
      bpSystolicTrend: MetricTrend(average: 118, highest: 122, lowest: 114, direction: 'Optimal', totalReadings: 3),
      bpDiastolicTrend: MetricTrend(average: 76, highest: 80, lowest: 72, direction: 'Normal', totalReadings: 3),
      glucoseTrend: MetricTrend(average: 88, direction: 'Normal', totalReadings: 2),
      pulseTrend: MetricTrend(average: 65, direction: 'Normal', totalReadings: 3),
      spo2Trend: MetricTrend(average: 99, direction: 'Normal', totalReadings: 3),
      tempTrend: MetricTrend(average: 36.7, direction: 'Normal', totalReadings: 2),
      weightTrend: MetricTrend(average: 74.0, direction: 'Normal', totalReadings: 2),
      bmiTrend: MetricTrend(average: 23.0, direction: 'Normal', totalReadings: 2),
      recentSymptoms: [],
      totalVitalsCount: 3,
    );

    test('Conversational Loop Step 1: Initial question yields interpretation and follow_up_suggestions', () async {
      final response = await aiService.askAssistant(
        "What does my blood pressure reading of 135/85 mean?",
        healthContext: mockPatientA,
      );

      // Verify direct clinical explanation
      expect(response, contains('Stage 1 Hypertension'));
      expect(response, contains('blood_pressure_card'));

      // Verify GenUI suggested follow-up card generation
      expect(response, contains('follow_up_suggestions'));
      expect(response, contains('Show my BP trend'));
      expect(response, contains('What can cause high BP?'));
      expect(response, contains('Explain systolic vs diastolic'));
      expect(response, contains('blood_pressure_history'));
    });

    test('Conversational Loop Step 2: Follow-up "Show my BP trend" generates trend chart & further actions', () async {
      // Simulate user tapping "Show my BP trend"
      final history = [
        ChatMessage(id: '1', conversationId: 'c1', sender: 'user', content: 'What does my blood pressure reading of 135/85 mean?', timestamp: DateTime.now()),
        ChatMessage(id: '2', conversationId: 'c1', sender: 'ai', content: 'Your reading is 135/85 (Stage 1 Hypertension)...', timestamp: DateTime.now()),
      ];

      final response = await aiService.askAssistant(
        "Show me this patient's blood pressure trend.",
        healthContext: mockPatientA,
        history: history,
      );

      expect(response, contains('Sarah Connor'));
      expect(response, contains('136/86 mmHg'));
      expect(response, contains('trend_chart'));
      expect(response, contains('follow_up_suggestions'));
      expect(response, contains('Why might this happen?'));
    });

    test('Conversational Loop Step 3: Continuity "Why might this happen?" understands previous BP context', () async {
      final history = [
        ChatMessage(id: '1', conversationId: 'c1', sender: 'user', content: 'Show me my blood pressure trend', timestamp: DateTime.now()),
        ChatMessage(id: '2', conversationId: 'c1', sender: 'ai', content: 'Blood pressure trend for Sarah Connor: average 136/86 mmHg (Elevated)...', timestamp: DateTime.now()),
      ];

      final response = await aiService.askAssistant(
        "Why might this happen?",
        healthContext: mockPatientA,
        history: history,
      );

      // Successfully inferred that "this" refers to Blood Pressure changes without user repeating it!
      expect(response, contains('Blood Pressure Dynamics'));
      expect(response, contains('Peripheral Vascular Resistance'));
      expect(response, contains('Dietary Sodium'));
      expect(response, contains('Sarah Connor'));
    });

    test('Conversational Loop Step 4: "Explain systolic vs diastolic" provides educational card and next steps', () async {
      final response = await aiService.askAssistant(
        "Explain systolic vs diastolic",
        healthContext: mockPatientA,
      );

      expect(response, contains('Systolic vs. Diastolic Blood Pressure Explained'));
      expect(response, contains('education_card'));
      expect(response, contains('follow_up_suggestions'));
    });

    test('Patient Isolation: Follow-ups maintain strict isolation between Patient A and Patient B', () async {
      // Query for Patient A (Sarah Connor)
      final responseA = await aiService.askAssistant(
        "Show me this patient's blood pressure trend.",
        healthContext: mockPatientA,
      );
      expect(responseA, contains('Sarah Connor'));
      expect(responseA, contains('136/86 mmHg'));
      expect(responseA, isNot(contains('John Connor')));

      // Query for Patient B (John Connor)
      final responseB = await aiService.askAssistant(
        "Show me this patient's blood pressure trend.",
        healthContext: mockPatientB,
      );
      expect(responseB, contains('John Connor'));
      expect(responseB, contains('118/76 mmHg'));
      expect(responseB, isNot(contains('Sarah Connor')));
    });
  });
}
