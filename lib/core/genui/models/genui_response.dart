import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'genui_action.dart';
import 'genui_component.dart';

/// Structured, schema-validated response from the GenUI engine or AI assistant.
class GenUiResponse extends Equatable {
  final String message;
  final List<GenUiComponent> components;
  final List<GenUiAction> suggestions;
  final Map<String, dynamic> context;
  final bool isValid;
  final List<String> errors;

  const GenUiResponse({
    required this.message,
    this.components = const [],
    this.suggestions = const [],
    this.context = const {},
    this.isValid = true,
    this.errors = const [],
  });

  factory GenUiResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message']?.toString() ?? json['text']?.toString() ?? '';

    // Parse components
    final rawComponents = json['components'] as List? ?? [];
    final List<GenUiComponent> components = [];
    for (final c in rawComponents) {
      if (c is Map) {
        components.add(GenUiComponent.fromJson(Map<String, dynamic>.from(c)));
      }
    }

    // Parse suggestions
    final rawSuggestions = json['suggestions'] as List? ??
        (json['suggested_actions'] as List?) ??
        (json['actions'] as List?) ??
        [];
    final List<GenUiAction> suggestions = [];
    for (final s in rawSuggestions) {
      if (s is Map) {
        suggestions.add(GenUiAction.fromJson(Map<String, dynamic>.from(s)));
      } else if (s is String) {
        suggestions.add(GenUiAction(
          id: s,
          type: GenUiActionType.fromString(s),
          label: s,
        ));
      }
    }

    final context = (json['context'] is Map)
        ? Map<String, dynamic>.from(json['context'] as Map)
        : <String, dynamic>{};

    return GenUiResponse(
      message: message,
      components: components,
      suggestions: suggestions,
      context: context,
      isValid: json['isValid'] != false,
      errors: (json['errors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Parses an AI output string that may contain markdown JSON blocks or `<gen_ui>` tags.
  factory GenUiResponse.fromRawAiText(String rawText, {Map<String, dynamic>? initialContext}) {
    if (rawText.trim().isEmpty) {
      return GenUiResponse(
        message: '',
        context: initialContext ?? const {},
      );
    }

    String cleanText = rawText;
    final List<GenUiComponent> components = [];
    final List<GenUiAction> suggestions = [];

    // 1. Check for <gen_ui>...</gen_ui> or <gen-ui>...</gen-ui> tags
    final genUiTagRegex = RegExp(r'<gen[-_]ui(?:\s+[^>]*)?>([\s\S]*?)<\/gen[-_]ui>', caseSensitive: false);
    for (final match in genUiTagRegex.allMatches(rawText)) {
      final inside = match.group(1)?.trim();
      if (inside != null && inside.isNotEmpty) {
        _tryParseJsonIntoComponents(inside, components, suggestions);
      }
    }
    cleanText = cleanText.replaceAll(genUiTagRegex, '');

    // 2. Check for ```json ... ``` blocks
    final jsonFenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
    for (final match in jsonFenceRegex.allMatches(cleanText)) {
      final inside = match.group(1)?.trim();
      if (inside != null && (inside.startsWith('{') || inside.startsWith('['))) {
        _tryParseJsonIntoComponents(inside, components, suggestions);
      }
    }
    cleanText = cleanText.replaceAll(jsonFenceRegex, '');

    // 3. Strip any leftover tags
    cleanText = cleanText
        .replaceAll(RegExp(r'<\/?(?:gen[-_]ui|ui)(?:\s+[^>]*)?>', caseSensitive: false), '')
        .trim();

    return GenUiResponse(
      message: cleanText,
      components: components,
      suggestions: suggestions,
      context: initialContext ?? const {},
    );
  }

  static void _tryParseJsonIntoComponents(
    String rawJson,
    List<GenUiComponent> componentsOut,
    List<GenUiAction> suggestionsOut,
  ) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map.containsKey('components') && map['components'] is List) {
          for (final c in map['components'] as List) {
            if (c is Map) {
              componentsOut.add(GenUiComponent.fromJson(Map<String, dynamic>.from(c)));
            }
          }
        } else if (map.containsKey('type')) {
          componentsOut.add(GenUiComponent.fromJson(map));
        }

        if (map.containsKey('suggestions') && map['suggestions'] is List) {
          for (final s in map['suggestions'] as List) {
            if (s is Map) {
              suggestionsOut.add(GenUiAction.fromJson(Map<String, dynamic>.from(s)));
            } else if (s is String) {
              suggestionsOut.add(GenUiAction(
                id: s,
                type: GenUiActionType.fromString(s),
                label: s,
              ));
            }
          }
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            componentsOut.add(GenUiComponent.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (_) {
      // Ignore unparseable snippet
    }
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'components': components.map((c) => c.toJson()).toList(),
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        if (context.isNotEmpty) 'context': context,
        'isValid': isValid,
        if (errors.isNotEmpty) 'errors': errors,
      };

  GenUiResponse copyWith({
    String? message,
    List<GenUiComponent>? components,
    List<GenUiAction>? suggestions,
    Map<String, dynamic>? context,
    bool? isValid,
    List<String>? errors,
  }) {
    return GenUiResponse(
      message: message ?? this.message,
      components: components ?? this.components,
      suggestions: suggestions ?? this.suggestions,
      context: context ?? this.context,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [
        message,
        components,
        suggestions,
        context,
        isValid,
        errors,
      ];
}

