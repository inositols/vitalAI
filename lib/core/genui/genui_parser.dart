import 'dart:convert';
import 'models/genui_component_model.dart';

/// Parses raw text or markdown JSON code blocks from Gemini responses into typed GenUI component models.
class GenUiParser {
  static final _jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);

  /// Extracts GenUI components embedded in response text.
  static List<GenUiComponentModel> parseComponents(String rawText) {
    final components = <GenUiComponentModel>[];

    // 1. Check if whole text is raw JSON object or array
    final trimmed = rawText.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        _parseDecoded(decoded, components);
        if (components.isNotEmpty) return components;
      } catch (_) {}
    }

    // 2. Extract embedded ```json ``` markdown code blocks
    final matches = _jsonBlockRegex.allMatches(rawText);
    for (final match in matches) {
      final jsonString = match.group(1)?.trim();
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonString);
          _parseDecoded(decoded, components);
        } catch (_) {
          // Gracefully ignore invalid JSON syntax
        }
      }
    }

    return components;
  }

  /// Removes JSON code blocks from response text for clean natural text rendering.
  static String cleanText(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map || decoded is List) return '';
      } catch (_) {}
    }
    return rawText.replaceAll(_jsonBlockRegex, '').trim();
  }

  static void _parseDecoded(dynamic decoded, List<GenUiComponentModel> targetList) {
    if (decoded is Map<String, dynamic>) {
      final model = parseSingleMap(decoded);
      if (model != null) targetList.add(model);
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final model = parseSingleMap(item);
          if (model != null) targetList.add(model);
        }
      }
    }
  }

  /// Maps a parsed JSON map to its corresponding GenUiComponentModel.
  static GenUiComponentModel? parseSingleMap(Map<String, dynamic> map) {
    final type = map['type']?.toString().toLowerCase() ?? '';

    switch (type) {
      case 'blood_pressure_card':
      case 'glucose_card':
      case 'pulse_card':
      case 'temperature_card':
      case 'weight_card':
      case 'spo2_card':
      case 'health_summary_card':
      case 'metric_summary':
      case 'summary':
      case 'metric':
        return GenUiMetricSummaryModel.fromJson(map);

      case 'trend_chart':
      case 'chart':
      case 'trend':
      case 'graph':
      case 'line_chart':
        return GenUiTrendChartModel.fromJson(map);

      case 'comparison_chart':
      case 'compare_chart':
      case 'vitals_comparison':
        return GenUiComparisonChartModel.fromJson(map);

      case 'education_card':
      case 'educational_tip':
      case 'tip':
      case 'educational':
      case 'advice':
        return GenUiEducationCardModel.fromJson(map);

      case 'recommendation_card':
      case 'recommendation':
      case 'ai_recommendation':
        return GenUiRecommendationCardModel.fromJson(map);

      case 'report_card':
      case 'health_report':
      case 'report':
        return GenUiReportCardModel.fromJson(map);

      case 'timeline_card':
      case 'health_timeline':
      case 'timeline':
        return GenUiTimelineCardModel.fromJson(map);

      case 'reminder_card':
      case 'medication_card':
      case 'reminder':
      case 'medication':
        return GenUiReminderCardModel.fromJson(map);

      case 'ai_insight_card':
      case 'ai_insight':
      case 'insight':
        return GenUiAiInsightCardModel.fromJson(map);

      case 'patient_profile_card':
      case 'patient_profile':
      case 'patient':
        return GenUiPatientProfileCardModel.fromJson(map);

      case 'action_button':
      case 'action':
      case 'button':
        return GenUiActionButtonModel.fromJson(map);

      default:
        // Graceful fallback model for unknown types
        if (type.isNotEmpty) {
          return GenUiFallbackModel.fromJson(map);
        }
        return null;
    }
  }
}
