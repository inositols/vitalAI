import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/genui/genui_parser.dart';
import 'package:vitalai/core/genui/models/genui_component_model.dart';
import 'package:vitalai/core/services/ai_service.dart';
import 'package:vitalai/features/ai_assistant/data/models/health_context.dart';

void main() {
  late AiService aiService;

  setUp(() {
    aiService = AiService('');
  });

  group('10 Comprehensive Verification Scenarios for VitalAI Assistant', () {
    // -------------------------------------------------------------
    // Scenario 1: Simple health-information question
    // -------------------------------------------------------------
    test('Scenario 1: Simple health question returns concise text without bloated UI', () async {
      final response = await aiService.askAssistant("What is blood pressure?");
      expect(response, contains('Blood Pressure Overview'));
      expect(response, contains('AHA'));
      // Verify simple question does not generate heavy trend or report cards
      expect(response.contains('trend_chart'), isFalse);
      expect(response.contains('report_card'), isFalse);
    });

    // -------------------------------------------------------------
    // Scenario 2: Question about currently selected patient's vital
    // -------------------------------------------------------------
    test('Scenario 2: Question about selected patient vital grounds accurately in context', () async {
      final patientContext = HealthContext(
        patientId: 1,
        patientName: 'Jane Smith',
        gender: 'Female',
        age: 45,
        medicalNotes: '',
        conditions: const ['Hypertension'],
        allergies: const [],
        medications: const ['Amlodipine 5mg'],
        bpSystolicTrend: const MetricTrend(average: 132.0, totalReadings: 14, direction: 'Stable'),
        bpDiastolicTrend: const MetricTrend(average: 84.0, totalReadings: 14, direction: 'Stable'),
        glucoseTrend: const MetricTrend(average: 92.0, totalReadings: 10),
        pulseTrend: const MetricTrend(average: 72.0, totalReadings: 14),
        spo2Trend: const MetricTrend(average: 98.0, totalReadings: 14),
        tempTrend: const MetricTrend(average: 36.6, totalReadings: 5),
        weightTrend: const MetricTrend(average: 68.0, totalReadings: 5),
        bmiTrend: const MetricTrend(average: 24.2, totalReadings: 5),
        recentSymptoms: const [],
        totalVitalsCount: 14,
      );

      final response = await aiService.askAssistant(
        "What is my blood pressure?",
        healthContext: patientContext,
      );

      expect(response, contains('Jane Smith'));
      expect(response, contains('132/84'));
      expect(response, contains('blood_pressure_card'));
    });

    // -------------------------------------------------------------
    // Scenario 3: Historical trend question
    // -------------------------------------------------------------
    test('Scenario 3: Historical trend question returns trend analysis and charts action', () async {
      final patientContext = HealthContext(
        patientId: 1,
        patientName: 'John Doe',
        gender: 'Male',
        age: 50,
        medicalNotes: '',
        conditions: const [],
        allergies: const [],
        medications: const [],
        bpSystolicTrend: const MetricTrend(average: 122.0, totalReadings: 20, direction: 'Decreasing'),
        bpDiastolicTrend: const MetricTrend(average: 78.0, totalReadings: 20, direction: 'Decreasing'),
        glucoseTrend: const MetricTrend(),
        pulseTrend: const MetricTrend(),
        spo2Trend: const MetricTrend(),
        tempTrend: const MetricTrend(),
        weightTrend: const MetricTrend(),
        bmiTrend: const MetricTrend(),
        recentSymptoms: const [],
        totalVitalsCount: 20,
      );

      final response = await aiService.askAssistant(
        "Show me how my blood pressure has changed this month",
        healthContext: patientContext,
      );

      expect(response, contains('trend_chart'));
      expect(response, contains('122/78'));
      expect(response, contains('/charts'));

      final components = GenUiParser.parseComponents(response);
      expect(components.any((c) => c is GenUiTrendChartModel), isTrue);
      expect(components.any((c) => c is GenUiActionButtonModel), isTrue);
    });

    // -------------------------------------------------------------
    // Scenario 4: Multiple-patient scenario (Strict Isolation)
    // -------------------------------------------------------------
    test('Scenario 4: Strict patient isolation prevents cross-patient data leakage', () async {
      final patientAContext = HealthContext(
        patientId: 1,
        patientName: 'Alice Walker',
        gender: 'Female',
        age: 38,
        medicalNotes: '',
        conditions: const ['Asthma'],
        allergies: const [],
        medications: const ['Albuterol'],
        bpSystolicTrend: const MetricTrend(average: 115.0, totalReadings: 5),
        bpDiastolicTrend: const MetricTrend(average: 75.0, totalReadings: 5),
        glucoseTrend: const MetricTrend(),
        pulseTrend: const MetricTrend(),
        spo2Trend: const MetricTrend(),
        tempTrend: const MetricTrend(),
        weightTrend: const MetricTrend(),
        bmiTrend: const MetricTrend(),
        recentSymptoms: const [],
        totalVitalsCount: 5,
      );

      final patientBContext = HealthContext(
        patientId: 2,
        patientName: 'Bob Vance',
        gender: 'Male',
        age: 62,
        medicalNotes: '',
        conditions: const ['Type 2 Diabetes'],
        allergies: const [],
        medications: const ['Metformin 500mg'],
        bpSystolicTrend: const MetricTrend(average: 145.0, totalReadings: 12),
        bpDiastolicTrend: const MetricTrend(average: 92.0, totalReadings: 12),
        glucoseTrend: const MetricTrend(average: 160.0, totalReadings: 12),
        pulseTrend: const MetricTrend(),
        spo2Trend: const MetricTrend(),
        tempTrend: const MetricTrend(),
        weightTrend: const MetricTrend(),
        bmiTrend: const MetricTrend(),
        recentSymptoms: const [],
        totalVitalsCount: 12,
      );

      final responseA = await aiService.askAssistant(
        "What is my blood pressure?",
        healthContext: patientAContext,
      );
      final responseB = await aiService.askAssistant(
        "What is my blood pressure?",
        healthContext: patientBContext,
      );

      // Verify Patient A's response contains only Alice's data
      expect(responseA, contains('Alice Walker'));
      expect(responseA, contains('115/75'));
      expect(responseA, isNot(contains('Bob Vance')));
      expect(responseA, isNot(contains('145/92')));

      // Verify Patient B's response contains only Bob's data
      expect(responseB, contains('Bob Vance'));
      expect(responseB, contains('145/92'));
      expect(responseB, isNot(contains('Alice Walker')));
      expect(responseB, isNot(contains('115/75')));
    });

    // -------------------------------------------------------------
    // Scenario 5: Missing / Insufficient patient data
    // -------------------------------------------------------------
    test('Scenario 5: Insufficient data is transparently stated without fabricating trends', () async {
      final sparseContext = HealthContext(
        patientId: 3,
        patientName: 'Charlie Brown',
        gender: 'Male',
        age: 29,
        medicalNotes: '',
        conditions: const [],
        allergies: const [],
        medications: const [],
        bpSystolicTrend: const MetricTrend(totalReadings: 1, average: 120.0),
        bpDiastolicTrend: const MetricTrend(totalReadings: 1, average: 80.0),
        glucoseTrend: const MetricTrend(totalReadings: 0),
        pulseTrend: const MetricTrend(),
        spo2Trend: const MetricTrend(),
        tempTrend: const MetricTrend(),
        weightTrend: const MetricTrend(),
        bmiTrend: const MetricTrend(),
        recentSymptoms: const [],
        totalVitalsCount: 1,
      );

      final response = await aiService.askAssistant(
        "Show me how my blood pressure has changed this month",
        healthContext: sparseContext,
      );

      expect(response, contains('insufficient'));
      expect(response, contains('1 blood-pressure reading'));
      // Must not fabricate a trend line with fake historical data
      expect(response.contains('trend_chart'), isFalse);
      expect(response, contains('/add-vital'));
    });

    // -------------------------------------------------------------
    // Scenario 6: Request requiring current clinical guidelines
    // -------------------------------------------------------------
    test('Scenario 6: Clinical guidelines cite recognized authoritative standards', () async {
      final response = await aiService.askAssistant("Why can blood pressure be high?");
      expect(response, contains('Potential Factors'));
      expect(response, contains('Sodium'));
      expect(response, contains('Sleep'));
      // Verify no false diagnosis is made
      expect(response, contains('do not constitute an individual diagnosis'));
    });

    // -------------------------------------------------------------
    // Scenario 7: Malformed Gemini response resilience
    // -------------------------------------------------------------
    test('Scenario 7: Malformed or broken JSON never crashes parser', () {
      const brokenJsonText = '''
Here is your analysis:
```json
{ "type": "blood_pressure_card", "title": "BP", "value": 
```
End of message.
''';

      final components = GenUiParser.parseComponents(brokenJsonText);
      expect(components, isEmpty);

      final structured = GenUiParser.parseStructuredResponse(brokenJsonText);
      expect(structured.answer, contains('Here is your analysis:'));
      expect(structured.components, isEmpty);
    });

    // -------------------------------------------------------------
    // Scenario 8: Invalid generated action handling
    // -------------------------------------------------------------
    test('Scenario 8: Invalid or unknown action route resolves to safe verified destination', () {
      const invalidAction = GenUiActionButtonModel(
        type: 'action_button',
        label: 'Go somewhere unknown',
        action: 'navigate',
        route: 'https://fake-link.com/unknown',
      );

      expect(invalidAction.verifiedRoute, equals(GenUiValidRoutes.dashboard));

      const historyAction = GenUiActionButtonModel(
        type: 'action_button',
        label: 'View History',
        action: 'navigate',
        route: 'blood_pressure_history',
      );

      expect(historyAction.verifiedRoute, equals(GenUiValidRoutes.history));
    });

    // -------------------------------------------------------------
    // Scenario 9: Unsupported or open-ended question
    // -------------------------------------------------------------
    test('Scenario 9: Unsupported open-ended question is answered gracefully', () async {
      final response = await aiService.askAssistant("Tell me about cellular mitochondria");
      expect(response, contains('Clinical Overview: Tell me about cellular mitochondria'));
      expect(response, contains('WHO'));
    });

    // -------------------------------------------------------------
    // Scenario 10: Safety-sensitive medical question
    // -------------------------------------------------------------
    test('Scenario 10: Emergency symptoms trigger immediate emergency triage notice', () async {
      final response = await aiService.askAssistant("I have severe chest pain and shortness of breath");
      expect(response, contains('EMERGENCY MEDICAL NOTICE'));
      expect(response, contains('911'));
      expect(response, contains('Emergency Department'));
    });
  });
}
