import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/gemini_model_provider.dart';
import '../../data/services/river_ai_service.dart';
import '../../domain/models/clinical_test_scenario.dart';
import 'model_eval_event.dart';
import 'model_eval_state.dart';

class ModelEvalBloc extends Bloc<ModelEvalEvent, ModelEvalState> {
  final RiverAiService riverService;
  final GeminiModelProvider geminiService;

  ModelEvalBloc({
    required this.riverService,
    required this.geminiService,
  }) : super(_createInitialState(riverService)) {
    on<ModelEvalInit>(_onInit);
    on<ModelEvalScenarioSelected>(_onScenarioSelected);
    on<ModelEvalProviderChanged>(_onProviderChanged);
    on<ModelEvalFormUpdated>(_onFormUpdated);
    on<ModelEvalExecuteRequested>(_onExecuteRequested);
    on<ModelEvalConfigUpdated>(_onConfigUpdated);
    on<ModelEvalClearResult>(_onClearResult);
  }

  static ModelEvalState _createInitialState(RiverAiService riverService) {
    final first = ClinicalTestScenario.scenarios.isNotEmpty
        ? ClinicalTestScenario.scenarios.first
        : null;

    return ModelEvalState(
      proxyUrl: riverService.proxyUrl,
      useProxy: riverService.useProxy,
      riverApiKey: riverService.apiKey,
      riverModel: riverService.modelName,
      isRiverConfigured: riverService.isConfigured,
      selectedScenario: first,
      prompt: first?.prompt ?? '',
      systemPrompt: first?.defaultSystemPrompt ?? ClinicalTestScenario.baseClinicalSystemPrompt,
      temperature: first?.defaultTemperature ?? 0.2,
      maxTokens: first?.defaultMaxTokens ?? 2048,
      requestJson: first?.requestJson ?? false,
    );
  }

  Future<void> _onInit(ModelEvalInit event, Emitter<ModelEvalState> emit) async {
    await riverService.init();
    emit(state.copyWith(
      useProxy: riverService.useProxy,
      proxyUrl: riverService.proxyUrl,
      riverApiKey: riverService.apiKey,
      riverModel: riverService.modelName,
      isRiverConfigured: riverService.isConfigured,
    ));
  }

  void _onScenarioSelected(
    ModelEvalScenarioSelected event,
    Emitter<ModelEvalState> emit,
  ) {
    final s = event.scenario;
    emit(state.copyWith(
      selectedScenario: s,
      prompt: s.prompt,
      systemPrompt: s.defaultSystemPrompt,
      temperature: s.defaultTemperature,
      maxTokens: s.defaultMaxTokens,
      requestJson: s.requestJson,
      clearError: true,
    ));
  }

  void _onProviderChanged(
    ModelEvalProviderChanged event,
    Emitter<ModelEvalState> emit,
  ) {
    emit(state.copyWith(
      activeProviderKey: event.providerKey,
      clearError: true,
    ));
  }

  void _onFormUpdated(
    ModelEvalFormUpdated event,
    Emitter<ModelEvalState> emit,
  ) {
    emit(state.copyWith(
      prompt: event.prompt,
      systemPrompt: event.systemPrompt,
      temperature: event.temperature,
      maxTokens: event.maxTokens,
      requestJson: event.requestJson,
    ));
  }

  Future<void> _onExecuteRequested(
    ModelEvalExecuteRequested event,
    Emitter<ModelEvalState> emit,
  ) async {
    final prompt = state.prompt.trim();
    if (prompt.isEmpty) {
      emit(state.copyWith(
        status: ModelEvalStatus.failure,
        errorMessage: 'Prompt cannot be empty. Please enter a question or select a scenario.',
      ));
      return;
    }

    emit(state.copyWith(
      status: ModelEvalStatus.loading,
      clearResult: true,
      clearError: true,
    ));

    final provider = state.activeProviderKey == 'river' ? riverService : geminiService;

    final result = await provider.evaluate(
      prompt: prompt,
      systemInstruction: state.systemPrompt.trim().isNotEmpty ? state.systemPrompt : null,
      temperature: state.temperature,
      maxTokens: state.maxTokens,
      requestJson: state.requestJson,
    );

    if (result.isSuccess) {
      emit(state.copyWith(
        status: ModelEvalStatus.success,
        result: result,
      ));
    } else {
      emit(state.copyWith(
        status: ModelEvalStatus.failure,
        result: result,
        errorMessage: result.error ?? 'Unknown inference failure.',
      ));
    }
  }

  Future<void> _onConfigUpdated(
    ModelEvalConfigUpdated event,
    Emitter<ModelEvalState> emit,
  ) async {
    await riverService.updateConfig(
      apiKey: event.apiKey,
      proxyUrl: event.proxyUrl,
      useProxy: event.useProxy,
      model: event.model,
    );

    emit(state.copyWith(
      useProxy: riverService.useProxy,
      proxyUrl: riverService.proxyUrl,
      riverApiKey: riverService.apiKey,
      riverModel: riverService.modelName,
      isRiverConfigured: riverService.isConfigured,
    ));
  }

  void _onClearResult(
    ModelEvalClearResult event,
    Emitter<ModelEvalState> emit,
  ) {
    emit(state.copyWith(
      clearResult: true,
      clearError: true,
      status: ModelEvalStatus.initial,
    ));
  }
}
