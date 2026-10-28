import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/model_eval_result.dart';
import '../../domain/services/ai_model_provider.dart';

/// Service implementing OpenAI-compatible Chat Completions API for River AI (zai-org/GLM-5.3-Flash).
///
/// Security:
/// - Supports local dev proxy (http://localhost:3001/api/chat or http://10.0.2.2:3001/api/chat)
///   which keeps credentials 100% outside the client application bundle.
/// - If connecting directly to River AI, reads the API key dynamically from FlutterSecureStorage
///   or --dart-define=RIVER_API_KEY. Credentials are NEVER hardcoded into source code.
class RiverAiService implements AiModelProvider {
  static const String defaultModel = 'zai-org/GLM-5.3-Flash';
  static const String directBaseUrl = 'https://api.river.ai/v1';

  // Default proxy URL for desktop/web is localhost:3001, for Android emulator 10.0.2.2:3001
  static String get defaultProxyUrl {
    if (kIsWeb) return 'http://localhost:3001/api/chat';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api/chat';
    }
    return 'http://localhost:3001/api/chat';
  }

  final FlutterSecureStorage? secureStorage;
  String _modelName;
  String _apiKey;
  String _proxyUrl;
  bool useProxy;

  RiverAiService({
    this.secureStorage,
    String? initialApiKey,
    String? initialModel,
    String? initialProxyUrl,
    this.useProxy = true,
  })  : _apiKey = initialApiKey ?? const String.fromEnvironment('RIVER_API_KEY'),
        _modelName = initialModel ?? defaultModel,
        _proxyUrl = initialProxyUrl ?? defaultProxyUrl;

  @override
  String get providerName => 'River AI';

  @override
  String get modelName => _modelName;

  String get proxyUrl => _proxyUrl;
  String get apiKey => _apiKey;

  @override
  bool get isConfigured {
    if (useProxy) return _proxyUrl.isNotEmpty;
    return _apiKey.trim().isNotEmpty;
  }

  /// Initialize and load saved configuration from secure storage
  Future<void> init() async {
    if (secureStorage != null) {
      final savedKey = await secureStorage!.read(key: 'river_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKey = savedKey.trim();
      }
      final savedProxy = await secureStorage!.read(key: 'river_proxy_url');
      if (savedProxy != null && savedProxy.isNotEmpty) {
        _proxyUrl = savedProxy.trim();
      }
      final savedUseProxy = await secureStorage!.read(key: 'river_use_proxy');
      if (savedUseProxy != null) {
        useProxy = savedUseProxy == 'true';
      }
    }
  }

  /// Update configuration dynamically
  Future<void> updateConfig({
    String? apiKey,
    String? model,
    String? proxyUrl,
    bool? useProxy,
  }) async {
    if (apiKey != null) {
      _apiKey = apiKey.trim();
      if (secureStorage != null) {
        await secureStorage!.write(key: 'river_api_key', value: _apiKey);
      }
    }
    if (model != null && model.isNotEmpty) {
      _modelName = model.trim();
    }
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      _proxyUrl = proxyUrl.trim();
      if (secureStorage != null) {
        await secureStorage!.write(key: 'river_proxy_url', value: _proxyUrl);
      }
    }
    if (useProxy != null) {
      this.useProxy = useProxy;
      if (secureStorage != null) {
        await secureStorage!.write(key: 'river_use_proxy', value: this.useProxy.toString());
      }
    }
  }

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
      if (useProxy) {
        return await _evaluateViaProxy(
          prompt: prompt,
          systemInstruction: systemInstruction,
          temperature: temperature,
          maxTokens: maxTokens,
          requestJson: requestJson,
          stopwatch: stopwatch,
        );
      } else {
        return await _evaluateDirect(
          prompt: prompt,
          systemInstruction: systemInstruction,
          temperature: temperature,
          maxTokens: maxTokens,
          requestJson: requestJson,
          stopwatch: stopwatch,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: 'Network or client error: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Evaluate using the local dev-proxy (credentials never enter the mobile app bundle)
  Future<ModelEvalResult> _evaluateViaProxy({
    required String prompt,
    String? systemInstruction,
    required double temperature,
    required int maxTokens,
    required bool requestJson,
    required Stopwatch stopwatch,
  }) async {
    final uri = Uri.parse(_proxyUrl);
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'prompt': prompt,
      'systemPrompt': systemInstruction,
      'model': _modelName,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'responseFormat': requestJson ? 'json_object' : 'text',
    });

    final http.Response response;
    try {
      response = await http.post(uri, headers: headers, body: body).timeout(
            const Duration(seconds: 45),
          );
    } catch (e) {
      stopwatch.stop();
      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: 'Unable to reach local proxy server at $_proxyUrl. '
            'Please verify the river-eval server is running (npm run dev in river-eval/) '
            'or switch to Direct API mode in Model Settings.\nDetails: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    stopwatch.stop();
    final latency = stopwatch.elapsedMilliseconds;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final content = data['content'] as String? ?? '';
      final reasoning = data['reasoningContent'] as String?;
      final usage = data['usage'] as Map<String, dynamic>?;

      return ModelEvalResult.success(
        provider: providerName,
        model: data['model'] as String? ?? _modelName,
        content: content,
        reasoningContent: reasoning,
        latencyMs: latency,
        promptTokens: usage?['promptTokens'] as int?,
        completionTokens: usage?['completionTokens'] as int?,
        totalTokens: usage?['totalTokens'] as int?,
        rawResponse: data,
      );
    } else {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {}

      final msg = errorData?['error'] as String? ??
          'Proxy responded with HTTP ${response.statusCode}: ${response.reasonPhrase}';

      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: msg,
        latencyMs: latency,
        rawResponse: errorData,
      );
    }
  }

  /// Evaluate using direct OpenAI-compatible endpoint at https://api.river.ai/v1
  Future<ModelEvalResult> _evaluateDirect({
    required String prompt,
    String? systemInstruction,
    required double temperature,
    required int maxTokens,
    required bool requestJson,
    required Stopwatch stopwatch,
  }) async {
    if (_apiKey.trim().isEmpty) {
      stopwatch.stop();
      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: 'River API Key is not configured. Please enter your River API key in the '
            'Model Test configuration sheet or switch to Local Dev Proxy mode.',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    final uri = Uri.parse('$directBaseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final messages = <Map<String, String>>[];
    if (systemInstruction != null && systemInstruction.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemInstruction.trim()});
    }
    messages.add({'role': 'user', 'content': prompt.trim()});

    final payload = <String, dynamic>{
      'model': _modelName,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    if (requestJson) {
      payload['response_format'] = {'type': 'json_object'};
    }

    final http.Response response;
    try {
      response = await http.post(uri, headers: headers, body: jsonEncode(payload)).timeout(
            const Duration(seconds: 45),
          );
    } catch (e) {
      stopwatch.stop();
      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: 'Network connection to River AI ($directBaseUrl) failed: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    stopwatch.stop();
    final latency = stopwatch.elapsedMilliseconds;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = data['choices'] as List<dynamic>?;
      final firstChoice = choices != null && choices.isNotEmpty ? choices[0] : null;
      final message = firstChoice?['message'] as Map<String, dynamic>?;

      final content = message?['content'] as String? ?? '';
      final reasoning = message?['reasoning_content'] as String?;
      final usage = data['usage'] as Map<String, dynamic>?;

      return ModelEvalResult.success(
        provider: providerName,
        model: data['model'] as String? ?? _modelName,
        content: content,
        reasoningContent: reasoning,
        latencyMs: latency,
        promptTokens: usage?['prompt_tokens'] as int?,
        completionTokens: usage?['completion_tokens'] as int?,
        totalTokens: usage?['total_tokens'] as int?,
        rawResponse: data,
      );
    } else {
      String errorMessage = 'River API returned HTTP ${response.statusCode}';
      Map<String, dynamic>? errBody;
      try {
        errBody = jsonDecode(response.body);
        if (errBody?['error'] is Map) {
          errorMessage = errBody!['error']['message'] ?? errorMessage;
        } else if (errBody?['error'] is String) {
          errorMessage = errBody!['error'];
        }
      } catch (_) {
        errorMessage = '$errorMessage: ${response.body}';
      }

      if (response.statusCode == 401) {
        errorMessage = 'Authentication failed (401): Invalid or expired River API key.';
      } else if (response.statusCode == 404) {
        errorMessage = 'Model not found (404): Model "$_modelName" was not found on River AI.';
      } else if (response.statusCode == 429) {
        errorMessage = 'Rate limit or quota exceeded (429) on River AI account.';
      }

      return ModelEvalResult.failure(
        provider: providerName,
        model: _modelName,
        error: errorMessage,
        latencyMs: latency,
        rawResponse: errBody,
      );
    }
  }
}
