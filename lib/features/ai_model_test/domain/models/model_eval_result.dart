import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents the normalized evaluation result from any AI model (River AI or Gemini).
class ModelEvalResult extends Equatable {
  final String provider;
  final String model;
  final String content;
  final String? reasoningContent;
  final int latencyMs;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final bool isJson;
  final Map<String, dynamic>? parsedJson;
  final Map<String, dynamic>? rawResponse;
  final String? error;

  const ModelEvalResult({
    required this.provider,
    required this.model,
    required this.content,
    this.reasoningContent,
    required this.latencyMs,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.isJson = false,
    this.parsedJson,
    this.rawResponse,
    this.error,
  });

  bool get isSuccess => error == null;

  factory ModelEvalResult.success({
    required String provider,
    required String model,
    required String content,
    String? reasoningContent,
    required int latencyMs,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    Map<String, dynamic>? rawResponse,
  }) {
    Map<String, dynamic>? parsed;
    bool validJson = false;

    // Check if the response is JSON
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
          validJson = true;
        }
      } catch (_) {
        validJson = false;
      }
    } else if (trimmed.contains('```json') || trimmed.contains('```')) {
      // Clean markdown code blocks
      final cleaned = trimmed
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
          validJson = true;
        }
      } catch (_) {
        validJson = false;
      }
    }

    return ModelEvalResult(
      provider: provider,
      model: model,
      content: content,
      reasoningContent: reasoningContent,
      latencyMs: latencyMs,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      isJson: validJson,
      parsedJson: parsed,
      rawResponse: rawResponse,
    );
  }

  factory ModelEvalResult.failure({
    required String provider,
    required String model,
    required String error,
    required int latencyMs,
    Map<String, dynamic>? rawResponse,
  }) {
    return ModelEvalResult(
      provider: provider,
      model: model,
      content: '',
      latencyMs: latencyMs,
      error: error,
      rawResponse: rawResponse,
    );
  }

  @override
  List<Object?> get props => [
        provider,
        model,
        content,
        reasoningContent,
        latencyMs,
        promptTokens,
        completionTokens,
        totalTokens,
        isJson,
        parsedJson,
        error,
      ];
}
