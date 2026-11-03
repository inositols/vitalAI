import 'dart:convert';
import 'models/genui_component_model.dart';

/// Parses raw text or markdown JSON code blocks from Gemini responses into typed GenUI component models.
class GenUiParser {
  static final _jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
  static final _xmlGenUiRegex = RegExp(
    r'<(?:gen[-_]?ui|ui)(?:\s+[^>]*)?>\s*((?:```(?:json)?\s*)?[\{\[][\s\S]*?[\}\]](?:\s*```)?)\s*<\/(?:gen[-_]?ui|ui)>',
    caseSensitive: false,
  );
  static final _strayGenUiRegex = RegExp(r'<\/?(?:gen[-_]?ui|ui)(?:\s+[^>]*)?>', caseSensitive: false);

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

    // 2. Extract from <gen_ui>...</gen_ui> or <ui>...</ui> XML tags
    final xmlMatches = _xmlGenUiRegex.allMatches(rawText);
    for (final match in xmlMatches) {
      var jsonString = match.group(1)?.trim();
      if (jsonString != null && jsonString.isNotEmpty) {
        // Strip nested ```json ... ``` if present
        final codeMatch = _jsonBlockRegex.firstMatch(jsonString);
        if (codeMatch != null) {
          jsonString = codeMatch.group(1)?.trim() ?? jsonString;
        }
        try {
          final decoded = jsonDecode(jsonString);
          _parseDecoded(decoded, components);
        } catch (_) {}
      }
    }

    // 3. Extract embedded ```json ``` markdown code blocks
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

    // De-duplicate if captured by both XML block and code block
    final uniqueComponents = <GenUiComponentModel>[];
    for (final c in components) {
      if (!uniqueComponents.contains(c)) {
        uniqueComponents.add(c);
      }
    }

    return uniqueComponents;
  }

  /// Removes JSON code blocks and `&lt;gen_ui&gt;` tags from response text for clean natural text rendering.
  static String cleanText(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map || decoded is List) return '';
      } catch (_) {}
    }
    var cleaned = rawText.replaceAll(_xmlGenUiRegex, '');
    cleaned = cleaned.replaceAll(_jsonBlockRegex, '');
    cleaned = cleaned.replaceAll(_strayGenUiRegex, '');
    return cleaned.trim();
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

      case 'follow_up_suggestions':
      case 'suggested_actions':
      case 'follow_ups':
      case 'suggested_follow_ups':
        return GenUiFollowUpSuggestionsModel.fromJson(map);

      case 'follow_up_question':
      case 'follow_up':
      case 'navigation':
      case 'navigation_action':
      case 'view_vital':
      case 'data_action':
      case 'information_expansion':
        return GenUiFollowUpActionModel.fromJson(map);

      case 'medication_intake_card':
      case 'medication_intake':
      case 'pill_reminder':
        return GenUiMedicationIntakeModel.fromJson(map);

      case 'lab_results_card':
      case 'lab_results':
      case 'lab_panel':
        return GenUiLabResultsModel.fromJson(map);

      case 'risk_gauge_card':
      case 'risk_gauge':
      case 'health_risk_gauge':
        return GenUiRiskGaugeModel.fromJson(map);

      case 'doctor_checklist_card':
      case 'doctor_checklist':
      case 'visit_checklist':
        return GenUiDoctorChecklistModel.fromJson(map);

      default:
        // Graceful fallback model for unknown types
        if (type.isNotEmpty) {
          return GenUiFallbackModel.fromJson(map);
        }
        return null;
    }
  }

  /// Parses a full structured response containing answer text, components, actions, and follow-ups.
  static GenUiStructuredResponse parseStructuredResponse(
    String rawText, {
    String defaultIntent = 'general_response',
  }) {
    try {
      final components = parseComponents(rawText);
      final clean = cleanText(rawText);

      final actionList = <GenUiActionButtonModel>[];
      final followUpList = <GenUiFollowUpAction>[];
      final contentComponents = <GenUiComponentModel>[];

      for (final comp in components) {
        if (comp is GenUiActionButtonModel) {
          actionList.add(comp);
        } else if (comp is GenUiFollowUpSuggestionsModel) {
          followUpList.addAll(comp.suggestions);
          contentComponents.add(comp);
        } else if (comp is GenUiFollowUpActionModel) {
          followUpList.add(comp.action);
          contentComponents.add(comp);
        } else {
          contentComponents.add(comp);
        }
      }

      return GenUiStructuredResponse(
        intent: defaultIntent,
        answer: clean.isNotEmpty ? clean : rawText,
        components: contentComponents,
        actions: actionList,
        followUps: followUpList,
      );
    } catch (_) {
      return GenUiStructuredResponse(
        intent: defaultIntent,
        answer: rawText,
        components: const [],
        actions: const [],
        followUps: const [],
      );
    }
  }
}

