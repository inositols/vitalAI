import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/genui/genui_parser.dart';
import 'package:vitalai/core/genui/models/genui_component_model.dart';
import 'package:vitalai/core/genui/models/genui_intent_model.dart';
import 'package:vitalai/core/genui/registry/widget_registry.dart';
import 'package:vitalai/core/genui/services/genui_cache_service.dart';
import 'package:vitalai/core/genui/services/genui_prompt_builder.dart';
import 'package:vitalai/core/services/ai_explanation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenUI Parser & Engine Tests', () {
    test('GenUiParser parses valid json blocks into typed component models', () {
      const input = '''
Your blood pressure is stable.

```json
{
  "type": "blood_pressure_card",
  "title": "Blood Pressure",
  "value": "120/80",
  "unit": "mmHg",
  "status": "normal"
}
```

Keep tracking daily.
''';

      final components = GenUiParser.parseComponents(input);
      expect(components.length, 1);
      expect(components.first, isA<GenUiMetricSummaryModel>());

      final summary = components.first as GenUiMetricSummaryModel;
      expect(summary.title, 'Blood Pressure');
      expect(summary.value, '120/80');

      final cleanText = GenUiParser.cleanText(input);
      expect(cleanText, contains('Your blood pressure is stable.'));
      expect(cleanText, contains('Keep tracking daily.'));
      expect(cleanText, isNot(contains('```json')));
    });

    test('GenUiParser parses <gen_ui> XML tags and cleanly strips tags from cleanText', () {
      const input = '''
Here is your blood pressure analysis:

<gen_ui>
{
  "type": "blood_pressure_card",
  "title": "Blood Pressure",
  "value": "118/76",
  "unit": "mmHg",
  "status": "normal"
}
</gen_ui>

Please continue monitoring.
''';

      final components = GenUiParser.parseComponents(input);
      expect(components.length, 1);
      expect(components.first, isA<GenUiMetricSummaryModel>());

      final cleanText = GenUiParser.cleanText(input);
      expect(cleanText, contains('Here is your blood pressure analysis:'));
      expect(cleanText, contains('Please continue monitoring.'));
      expect(cleanText, isNot(contains('<gen_ui>')));
      expect(cleanText, isNot(contains('</gen_ui>')));
      expect(cleanText, isNot(contains('blood_pressure_card')));
    });

    test('GenUiParser strips orphan/stray <gen_ui> tags from output', () {
      const stray = 'Your vitals look normal. <gen_ui> Stay well! <gen-ui> <ui> All good </ui> </gen_ui>';
      final clean = GenUiParser.cleanText(stray);
      expect(clean, isNot(contains('<gen_ui>')));
      expect(clean, isNot(contains('<gen-ui>')));
      expect(clean, isNot(contains('<ui>')));
      expect(clean, isNot(contains('</ui>')));
      expect(clean, isNot(contains('</gen_ui>')));
      expect(clean, contains('Your vitals look normal.'));
      expect(clean, contains('Stay well!'));
    });

    test('GenUiParser handles <gen_ui type="card"> with attributes or hyphens', () {
      const input = '''
Clinical note:
<gen-ui type="blood_pressure">
{
  "type": "blood_pressure_card",
  "title": "Blood Pressure",
  "value": "125/82",
  "unit": "mmHg",
  "status": "normal"
}
</gen-ui>
Everything is in order.
''';
      final components = GenUiParser.parseComponents(input);
      expect(components.length, 1);
      expect(components.first, isA<GenUiMetricSummaryModel>());

      final cleanText = GenUiParser.cleanText(input);
      expect(cleanText, isNot(contains('<gen-ui')));
      expect(cleanText, isNot(contains('</gen-ui>')));
      expect(cleanText, contains('Clinical note:'));
      expect(cleanText, contains('Everything is in order.'));
    });

    test('GenUiIntentModel classifies user prompts accurately', () {
      final summaryIntent = GenUiIntentModel.fromQuery("Show me today's health summary.");
      expect(summaryIntent.intentType, GenUiIntentType.healthSummary);

      final trendIntent = GenUiIntentModel.fromQuery("Compare my blood pressure over the last month.");
      expect(trendIntent.intentType, GenUiIntentType.trendAnalysis);

      final eduIntent = GenUiIntentModel.fromQuery("What is systolic pressure?");
      expect(eduIntent.intentType, GenUiIntentType.educational);

      final reportIntent = GenUiIntentModel.fromQuery("Generate my health report.");
      expect(reportIntent.intentType, GenUiIntentType.reportGenerator);

      final timelineIntent = GenUiIntentModel.fromQuery("Show my health over the last six months.");
      expect(timelineIntent.intentType, GenUiIntentType.healthTimeline);
    });

    test('WidgetRegistry registers default components', () {
      final registry = WidgetRegistry();
      expect(registry, isNotNull);
    });

    test('GenUiPromptBuilder generates system instruction with registered types', () {
      final prompt = GenUiPromptBuilder.buildSystemInstruction();
      expect(prompt, contains('Registered GenUI Component Types'));
      expect(prompt, contains('blood_pressure_card'));
      expect(prompt, contains('report_card'));
      expect(prompt, contains('recommendation_card'));
      expect(prompt, contains('medication_intake_card'));
      expect(prompt, contains('lab_results_card'));
      expect(prompt, contains('risk_gauge_card'));
      expect(prompt, contains('doctor_checklist_card'));
    });

    test('GenUiParser parses medication_intake_card, lab_results_card, risk_gauge_card, and doctor_checklist_card', () {
      const input = '''
Clinical recommendations for your review:

```json
{
  "type": "medication_intake_card",
  "medicationName": "Lisinopril",
  "dosage": "10 mg",
  "scheduledTime": "08:00 AM",
  "instructions": "Take once daily in morning with water."
}
```

```json
{
  "type": "lab_results_card",
  "panelName": "Lipid Panel",
  "collectionDate": "Oct 1, 2026",
  "analytes": [
    {
      "name": "Total Cholesterol",
      "value": "195",
      "unit": "mg/dL",
      "referenceRange": "< 200 mg/dL",
      "status": "normal"
    },
    {
      "name": "LDL",
      "value": "128",
      "unit": "mg/dL",
      "referenceRange": "< 100 mg/dL",
      "status": "elevated"
    }
  ]
}
```

```json
{
  "type": "risk_gauge_card",
  "title": "Cardiovascular Risk Score",
  "scorePercentage": 12.4,
  "riskLevel": "moderate",
  "categoryDescription": "10-Year ASCVD Risk Estimate",
  "contributingFactors": ["Systolic BP 134 mmHg", "Age 54"],
  "recommendation": "Maintain aerobic exercise and low-sodium diet."
}
```

```json
{
  "type": "doctor_checklist_card",
  "title": "Doctor Visit Discussion Guide",
  "appointmentFocus": "Hypertension & medication checkup",
  "checklistItems": [
    {
      "question": "Should my lisinopril dosage be adjusted?"
    },
    {
      "question": "How often should I monitor BP at home?"
    }
  ]
}
```
''';

      final components = GenUiParser.parseComponents(input);
      expect(components.length, 4);

      expect(components[0], isA<GenUiMedicationIntakeModel>());
      final med = components[0] as GenUiMedicationIntakeModel;
      expect(med.medicationName, 'Lisinopril');
      expect(med.dosage, '10 mg');

      expect(components[1], isA<GenUiLabResultsModel>());
      final lab = components[1] as GenUiLabResultsModel;
      expect(lab.panelName, 'Lipid Panel');
      expect(lab.analytes.length, 2);
      expect(lab.analytes[0].name, 'Total Cholesterol');

      expect(components[2], isA<GenUiRiskGaugeModel>());
      final risk = components[2] as GenUiRiskGaugeModel;
      expect(risk.riskLevel, 'moderate');
      expect(risk.scorePercentage, 12.4);

      expect(components[3], isA<GenUiDoctorChecklistModel>());
      final doc = components[3] as GenUiDoctorChecklistModel;
      expect(doc.checklistItems.length, 2);
      expect(doc.checklistItems[0].question, 'Should my lisinopril dosage be adjusted?');
    });

    test('GenUiCacheService caches and retrieves response payloads', () async {
      await GenUiCacheService.cacheResponse('test_prompt', 'Cached GenUI Payload');
      final result = await GenUiCacheService.getCachedResponse('test_prompt');
      expect(result, 'Cached GenUI Payload');
    });

    test('AiExplanationService provides non-diagnostic metric explanations', () {
      final explanation = AiExplanationService.explainMetric('spo2');
      expect(explanation, contains('SpO₂'));
      expect(explanation, contains('does not constitute medical diagnosis'));
      expect(explanation, contains('consult a qualified healthcare professional'));
    });
  });
}

