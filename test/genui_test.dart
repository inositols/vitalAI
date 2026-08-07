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
