import '../models/model_eval_result.dart';

/// Pluggable interface for AI Model evaluation.
/// Enables seamless side-by-side comparison between River AI (zai-org/GLM-5.3-Flash)
/// and Google Gemini models within VitalAI.
abstract class AiModelProvider {
  /// User-facing provider name (e.g. 'River AI', 'Google Gemini')
  String get providerName;

  /// Underlying model identifier (e.g. 'zai-org/GLM-5.3-Flash', 'gemini-3.8-flash')
  String get modelName;

  /// Whether the provider has credentials/connection available
  bool get isConfigured;

  /// Execute an evaluation request
  Future<ModelEvalResult> evaluate({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.2,
    int maxTokens = 2048,
    bool requestJson = false,
  });
}
