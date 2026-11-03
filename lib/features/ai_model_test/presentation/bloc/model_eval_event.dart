import 'package:equatable/equatable.dart';
import '../../domain/models/clinical_test_scenario.dart';

abstract class ModelEvalEvent extends Equatable {
  const ModelEvalEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the model eval bloc and load saved provider configuration
class ModelEvalInit extends ModelEvalEvent {
  const ModelEvalInit();
}

/// Select a pre-configured clinical scenario
class ModelEvalScenarioSelected extends ModelEvalEvent {
  final ClinicalTestScenario scenario;

  const ModelEvalScenarioSelected(this.scenario);

  @override
  List<Object?> get props => [scenario];
}

/// Switch active provider ('river' or 'gemini')
class ModelEvalProviderChanged extends ModelEvalEvent {
  final String providerKey; // 'river' or 'gemini'

  const ModelEvalProviderChanged(this.providerKey);

  @override
  List<Object?> get props => [providerKey];
}

/// Update prompt or parameter values in the editor
class ModelEvalFormUpdated extends ModelEvalEvent {
  final String? prompt;
  final String? systemPrompt;
  final double? temperature;
  final int? maxTokens;
  final bool? requestJson;

  const ModelEvalFormUpdated({
    this.prompt,
    this.systemPrompt,
    this.temperature,
    this.maxTokens,
    this.requestJson,
  });

  @override
  List<Object?> get props => [prompt, systemPrompt, temperature, maxTokens, requestJson];
}

/// Execute evaluation
class ModelEvalExecuteRequested extends ModelEvalEvent {
  const ModelEvalExecuteRequested();
}

/// Update River configuration (proxy mode vs direct API, API key, proxy URL)
class ModelEvalConfigUpdated extends ModelEvalEvent {
  final String? apiKey;
  final String? proxyUrl;
  final bool? useProxy;
  final String? model;

  const ModelEvalConfigUpdated({
    this.apiKey,
    this.proxyUrl,
    this.useProxy,
    this.model,
  });

  @override
  List<Object?> get props => [apiKey, proxyUrl, useProxy, model];
}

/// Clear current evaluation result
class ModelEvalClearResult extends ModelEvalEvent {
  const ModelEvalClearResult();
}
