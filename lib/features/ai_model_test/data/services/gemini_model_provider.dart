import 'package:flutter/foundation.dart';
import '../../../../core/services/ai_service.dart';
import '../../domain/models/model_eval_result.dart';
import '../../domain/services/ai_model_provider.dart';

/// Wraps VitalAI's existing AiService to implement AiModelProvider for comparative benchmarking.
class GeminiModelProvider implements AiModelProvider {
  final AiService _aiService;

  GeminiModelProvider(this._aiService);

  @override
  String get providerName => 'Google Gemini';

  @override
  String get modelName => 'gemini-3.8-flash';

  @override
  bool get isConfigured => _aiService.isConfigured;

  @override
  Future<ModelEvalResult> evaluate({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.2,
    int maxTokens = 2048,
    bool requestJson = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final combinedPrompt = StringBuffer();
      if (systemInstruction != null && systemInstruction.trim().isNotEmpty) {
        combinedPrompt.writeln('System Instruction: $systemInstruction');
        combinedPrompt.writeln('---');
      }
      if (requestJson) {
        combinedPrompt.writeln('Output strictly valid JSON with no markdown wrapping.');
      }
      combinedPrompt.writeln(prompt);

      final responseText = await _aiService.askAssistant(combinedPrompt.toString());
      stopwatch.stop();

      final latency = stopwatch.elapsedMilliseconds;

      return ModelEvalResult.success(
        provider: providerName,
        model: modelName,
        content: responseText,
        latencyMs: latency,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('GeminiModelProvider error: $e');
      return ModelEvalResult.failure(
        provider: providerName,
        model: modelName,
        error: 'Gemini Error: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}
