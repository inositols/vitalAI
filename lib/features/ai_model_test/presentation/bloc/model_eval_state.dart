import 'package:equatable/equatable.dart';
import '../../domain/models/clinical_test_scenario.dart';
import '../../domain/models/model_eval_result.dart';

enum ModelEvalStatus { initial, loading, success, failure }

class ModelEvalState extends Equatable {
  final ModelEvalStatus status;
  final String activeProviderKey; // 'river' or 'gemini'
  final ClinicalTestScenario? selectedScenario;
  final String prompt;
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final bool requestJson;
  final ModelEvalResult? result;
  final String? errorMessage;

  // River configuration status
  final bool useProxy;
  final String proxyUrl;
  final String riverApiKey;
  final String riverModel;
  final bool isRiverConfigured;

  const ModelEvalState({
    this.status = ModelEvalStatus.initial,
    this.activeProviderKey = 'river',
    this.selectedScenario,
    this.prompt = '',
    this.systemPrompt = ClinicalTestScenario.baseClinicalSystemPrompt,
    this.temperature = 0.2,
    this.maxTokens = 2048,
    this.requestJson = false,
    this.result,
    this.errorMessage,
    this.useProxy = true,
    this.proxyUrl = 'http://localhost:3001/api/chat',
    this.riverApiKey = '',
    this.riverModel = 'zai-org/GLM-5.3-Flash',
    this.isRiverConfigured = true,
  });

  bool get isLoading => status == ModelEvalStatus.loading;

  ModelEvalState copyWith({
    ModelEvalStatus? status,
    String? activeProviderKey,
    ClinicalTestScenario? selectedScenario,
    String? prompt,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool? requestJson,
    ModelEvalResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? useProxy,
    String? proxyUrl,
    String? riverApiKey,
    String? riverModel,
    bool? isRiverConfigured,
  }) {
    return ModelEvalState(
      status: status ?? this.status,
      activeProviderKey: activeProviderKey ?? this.activeProviderKey,
      selectedScenario: selectedScenario ?? this.selectedScenario,
      prompt: prompt ?? this.prompt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      requestJson: requestJson ?? this.requestJson,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      useProxy: useProxy ?? this.useProxy,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      riverApiKey: riverApiKey ?? this.riverApiKey,
      riverModel: riverModel ?? this.riverModel,
      isRiverConfigured: isRiverConfigured ?? this.isRiverConfigured,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeProviderKey,
        selectedScenario,
        prompt,
        systemPrompt,
        temperature,
        maxTokens,
        requestJson,
        result,
        errorMessage,
        useProxy,
        proxyUrl,
        riverApiKey,
        riverModel,
        isRiverConfigured,
      ];
}
