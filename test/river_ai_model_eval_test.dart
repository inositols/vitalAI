import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalai/features/ai_model_test/domain/models/clinical_test_scenario.dart';
import 'package:vitalai/features/ai_model_test/domain/models/model_eval_result.dart';
import 'package:vitalai/features/ai_model_test/data/services/river_ai_service.dart';
import 'package:vitalai/features/ai_model_test/data/services/gemini_model_provider.dart';
import 'package:vitalai/features/ai_model_test/presentation/bloc/model_eval_bloc.dart';
import 'package:vitalai/features/ai_model_test/presentation/bloc/model_eval_event.dart';
import 'package:vitalai/features/ai_model_test/presentation/bloc/model_eval_state.dart';

class MockRiverAiService extends Mock implements RiverAiService {}
class MockGeminiModelProvider extends Mock implements GeminiModelProvider {}

void main() {
  group('ClinicalTestScenario Scenarios & Pre-configurations', () {
    test('contains all 7 required evaluation scenarios', () {
      final scenarios = ClinicalTestScenario.scenarios;
      expect(scenarios.length, 7);

      final ids = scenarios.map((s) => s.id).toList();
      expect(ids, contains('blood_pressure'));
      expect(ids, contains('blood_glucose'));
      expect(ids, contains('trends'));
      expect(ids, contains('medications'));
      expect(ids, contains('missing_context'));
      expect(ids, contains('urgent_symptoms'));
      expect(ids, contains('genui_json'));
    });

    test('urgent symptoms scenario includes critical emergency triage instructions', () {
      final urgentScenario = ClinicalTestScenario.scenarios.firstWhere((s) => s.id == 'urgent_symptoms');
      expect(urgentScenario.evaluationObjectives, anyElement(contains('911')));
      expect(urgentScenario.evaluationObjectives, anyElement(contains('Acute Coronary Syndrome')));
      expect(urgentScenario.defaultTemperature, 0.0);
    });

    test('genui scenario specifies strict json_object format', () {
      final genuiScenario = ClinicalTestScenario.scenarios.firstWhere((s) => s.id == 'genui_json');
      expect(genuiScenario.requestJson, isTrue);
      expect(genuiScenario.prompt, contains('Generate a VitalAI GenUI card'));
    });
  });

  group('ModelEvalResult JSON parsing tests', () {
    test('successfully parses raw JSON object string', () {
      const jsonStr = '{"cardType": "METRIC_ALERT", "metric": {"primaryValue": 192}}';
      final result = ModelEvalResult.success(
        provider: 'River AI',
        model: 'zai-org/GLM-5.3-Flash',
        content: jsonStr,
        latencyMs: 1200,
        promptTokens: 50,
        completionTokens: 80,
        totalTokens: 130,
      );

      expect(result.isJson, isTrue);
      expect(result.parsedJson, isNotNull);
      expect(result.parsedJson!['cardType'], 'METRIC_ALERT');
      expect(result.parsedJson!['metric']['primaryValue'], 192);
      expect(result.promptTokens, 50);
      expect(result.completionTokens, 80);
      expect(result.totalTokens, 130);
    });

    test('successfully cleans and parses markdown code fence wrapped JSON', () {
      const wrappedJson = '```json\n{"cardType": "METRIC_NORMAL", "summary": "Normal vitals"}\n```';
      final result = ModelEvalResult.success(
        provider: 'River AI',
        model: 'zai-org/GLM-5.3-Flash',
        content: wrappedJson,
        latencyMs: 850,
      );

      expect(result.isJson, isTrue);
      expect(result.parsedJson!['cardType'], 'METRIC_NORMAL');
      expect(result.parsedJson!['summary'], 'Normal vitals');
    });

    test('marks non-JSON text as isJson = false', () {
      const plainText = 'According to AHA guidelines, 120/80 is normal.';
      final result = ModelEvalResult.success(
        provider: 'River AI',
        model: 'zai-org/GLM-5.3-Flash',
        content: plainText,
        latencyMs: 650,
      );

      expect(result.isJson, isFalse);
      expect(result.parsedJson, isNull);
    });
  });

  group('ModelEvalBloc Tests', () {
    late MockRiverAiService mockRiverService;
    late MockGeminiModelProvider mockGeminiService;

    setUp(() {
      mockRiverService = MockRiverAiService();
      mockGeminiService = MockGeminiModelProvider();

      when(() => mockRiverService.proxyUrl).thenReturn('http://localhost:3001/api/chat');
      when(() => mockRiverService.useProxy).thenReturn(true);
      when(() => mockRiverService.apiKey).thenReturn('');
      when(() => mockRiverService.modelName).thenReturn('zai-org/GLM-5.3-Flash');
      when(() => mockRiverService.isConfigured).thenReturn(true);
      when(() => mockRiverService.init()).thenAnswer((_) async {});
    });

    test('initial state loads first clinical scenario by default', () {
      final bloc = ModelEvalBloc(
        riverService: mockRiverService,
        geminiService: mockGeminiService,
      );

      expect(bloc.state.selectedScenario?.id, 'blood_pressure');
      expect(bloc.state.prompt, contains('142/92 mmHg'));
      expect(bloc.state.activeProviderKey, 'river');
      expect(bloc.state.isRiverConfigured, isTrue);
    });

    test('switching scenarios updates prompt and parameters', () {
      final bloc = ModelEvalBloc(
        riverService: mockRiverService,
        geminiService: mockGeminiService,
      );

      final glucoseScenario = ClinicalTestScenario.scenarios.firstWhere((s) => s.id == 'blood_glucose');
      bloc.add(ModelEvalScenarioSelected(glucoseScenario));

      expect(bloc.stream, emits(predicate<ModelEvalState>((state) {
        return state.selectedScenario?.id == 'blood_glucose' &&
            state.prompt.contains('114 mg/dL') &&
            state.prompt.contains('158 mg/dL');
      })));
    });

    test('switching active provider to gemini updates state', () {
      final bloc = ModelEvalBloc(
        riverService: mockRiverService,
        geminiService: mockGeminiService,
      );

      bloc.add(const ModelEvalProviderChanged('gemini'));

      expect(bloc.stream, emits(predicate<ModelEvalState>((state) {
        return state.activeProviderKey == 'gemini';
      })));
    });

    test('executes River evaluation and emits success result with latency and tokens', () async {
      when(() => mockRiverService.evaluate(
            prompt: any(named: 'prompt'),
            systemInstruction: any(named: 'systemInstruction'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
            requestJson: any(named: 'requestJson'),
          )).thenAnswer((_) async => ModelEvalResult.success(
            provider: 'River AI',
            model: 'zai-org/GLM-5.3-Flash',
            content: 'Stage 2 Hypertension under ACC/AHA guidelines.',
            reasoningContent: 'Assessing 142/92 systolic/diastolic thresholds...',
            latencyMs: 1420,
            promptTokens: 45,
            completionTokens: 25,
            totalTokens: 70,
          ));

      final bloc = ModelEvalBloc(
        riverService: mockRiverService,
        geminiService: mockGeminiService,
      );

      bloc.add(const ModelEvalExecuteRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ModelEvalState>((s) => s.status == ModelEvalStatus.loading),
          predicate<ModelEvalState>((s) =>
              s.status == ModelEvalStatus.success &&
              s.result?.content == 'Stage 2 Hypertension under ACC/AHA guidelines.' &&
              s.result?.latencyMs == 1420 &&
              s.result?.reasoningContent != null &&
              s.result?.totalTokens == 70),
        ]),
      );
    });
  });
}
