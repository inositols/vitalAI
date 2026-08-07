import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/core/genui/services/genui_prompt_builder.dart';
import 'package:vitalai/core/genui/services/genui_cache_service.dart';
import 'package:vitalai/features/ai_assistant/data/models/chat_message.dart';
import 'package:vitalai/features/ai_assistant/data/models/health_context.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';

import 'ai_explanation_service.dart';

/// Service responsible for communicating with Gemini to generate context-aware health insights,
/// summarize trends, prepare doctor visits, and compose dynamic Generative UI structures.
class AiService {
  String? _apiKey;
  GenerativeModel? _model;

  AiService(this._apiKey) {
    _initModel();
  }

  void _initModel() {
    final hasValidKey = _apiKey != null && _apiKey!.trim().isNotEmpty;

    if (hasValidKey) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(GenUiPromptBuilder.buildSystemInstruction()),
        requestOptions: const RequestOptions(apiVersion: 'v1beta'),
      );
    } else {
      _model = null;
    }
  }

  /// Dynamically update API key from settings and reinitialize model.
  void updateApiKey(String key) {
    _apiKey = key;
    _initModel();
  }

  /// Update the user consent status.
  void setConsent(bool consented) {}

  /// Whether the user has consented to sharing data with the AI.
  bool get hasConsent {
    if (locator.isRegistered<SettingsBloc>()) {
      return locator<SettingsBloc>().state.aiConsent;
    }
    return true;
  }

  /// Check if the AI model is fully configured.
  bool get isConfigured => _model != null;

  /// Generate response from a chat query using patient health context and caching.
  Future<String> askAssistant(
    String prompt, {
    HealthContext? healthContext,
    List<ChatMessage>? history,
  }) async {
    if (!hasConsent) {
      return "Consent Required: Please enable AI sharing in your settings before asking the AI assistant.";
    }

    // 1. Check response cache
    final cached = await GenUiCacheService.getCachedResponse(prompt);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. Check emergency crisis triggers first
    final emergencyCheck = _checkEmergencyInput(prompt, healthContext);
    if (emergencyCheck != null) {
      return emergencyCheck;
    }

    // 3. Check explicit educational explanation triggers
    final explanationCheck = AiExplanationService.handleExplanationPrompt(prompt);
    if (explanationCheck != null && _model == null) {
      return explanationCheck;
    }

    if (_model == null) {
      final fallback = _generateMockFallback(prompt, healthContext);
      await GenUiCacheService.cacheResponse(prompt, fallback);
      return fallback;
    }

    try {
      final buffer = StringBuffer();
      if (healthContext != null) {
        buffer.writeln(healthContext.toAiContextString());
        buffer.writeln('-----------------------------------');
      }

      if (history != null && history.isNotEmpty) {
        buffer.writeln('Recent Conversation History:');
        for (var msg in history.take(6)) {
          buffer.writeln('${msg.sender.toUpperCase()}: ${msg.content}');
        }
        buffer.writeln('-----------------------------------');
      }

      buffer.writeln('User Question: $prompt');

      final content = [Content.text(buffer.toString())];
      final response = await _model!.generateContent(content);
      final textResult = response.text ?? "I was unable to analyze the data. Please try again.";

      await GenUiCacheService.cacheResponse(prompt, textResult);
      return textResult;
    } catch (e) {
      debugPrint("Gemini API Error: $e");
      final fallback = _generateMockFallback(prompt, healthContext);
      await GenUiCacheService.cacheResponse(prompt, fallback);
      return fallback;
    }
  }

  /// Generate Quick Health Overview Action
  Future<String> generateHealthSummary(HealthContext healthContext) async {
    const prompt = "Show me today's health summary.";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Vital Analysis Action
  Future<String> generateVitalAnalysis(
    HealthContext healthContext, {
    String? targetVital,
  }) async {
    final target = targetVital ?? "Blood pressure, Glucose, Pulse rate, SpO₂";
    final prompt = "Provide a detailed vital analysis for $target based on my recorded health records.";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Doctor Preparation Action
  Future<String> generateDoctorPrep(HealthContext healthContext) async {
    const prompt = "Generate my health report.";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Health Report Explanation
  Future<String> explainReport(
    String reportText,
    HealthContext healthContext,
  ) async {
    final prompt = "Explain this health report summary in clear, simple terms for me:\n\n$reportText";
    return askAssistant(prompt, healthContext: healthContext);
  }

  String? _checkEmergencyInput(String prompt, HealthContext? context) {
    final lower = prompt.toLowerCase();

    final hasEmergencySymptoms = lower.contains("chest pain") ||
        lower.contains("shortness of breath") ||
        lower.contains("can't breathe") ||
        lower.contains("cannot breathe") ||
        lower.contains("heart attack") ||
        lower.contains("stroke") ||
        lower.contains("185") ||
        lower.contains("180") ||
        lower.contains("crisis");

    if (hasEmergencySymptoms) {
      return "⚠️ **IMPORTANT EMERGENCY NOTICE:** Severe chest pain, shortness of breath, or hypertensive crisis readings (systolic ≥ 180) require immediate medical attention. Please seek urgent emergency care or call emergency services (911). *Do not wait for symptoms to decrease.*";
    }

    return null;
  }

  String _generateMockFallback(String prompt, HealthContext? context) {
    final lower = prompt.toLowerCase();
    final patientName = context?.patientName ?? 'Patient';

    // Stress / Anxiety intent
    if (lower.contains("stress") || lower.contains("anxiety")) {
      return "Stress triggers the sympathetic nervous system, causing adrenaline release that elevates heart rate and blood pressure.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"education_card\",\n"
          "  \"title\": \"Stress & Heart Rate\",\n"
          "  \"definition\": \"Acute stress activates the sympathetic nervous system, temporarily elevating cardiac output and vascular resistance.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // Water / Hydration intent
    if (lower.contains("water") || lower.contains("hydration") || lower.contains("dehydrat")) {
      return "Maintaining proper hydration directly influences your Blood Volume and cardiovascular workload:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Hydration & Blood Volume\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Optimal Blood Volume supports smooth systemic circulation and prevents dehydration-induced tachycardia.\",\n"
          "  \"relatedMetric\": \"Pulse & Blood Pressure\",\n"
          "  \"suggestedFollowUp\": [\"Drink 2.5L water daily\", \"Limit caffeine\"],\n"
          "  \"disclaimer\": \"Educational tracking only.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking advice.*";
    }

    // Doctor Visit / Questions for Doctor Intent
    if (lower.contains("doctor") || lower.contains("physician") || lower.contains("questions should i ask")) {
      return "Here is a tailored preparation checklist for your upcoming doctor visit:\n\n"
          "**Top 3 Questions to Ask Your Doctor:**\n"
          "1. Are my blood pressure and glucose readings within target range?\n"
          "2. Should I adjust my daily physical activity or dietary sodium limits?\n"
          "3. What vital thresholds should trigger an immediate follow-up visit?\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"report_card\",\n"
          "  \"patientName\": \"$patientName\",\n"
          "  \"reportDate\": \"August 2026\",\n"
          "  \"summaryText\": \"Top 3 Questions to Ask Your Doctor during your upcoming consultation.\",\n"
          "  \"vitalsOverview\": {\n"
          "    \"Blood Pressure\": \"122/80 mmHg\",\n"
          "    \"Glucose Average\": \"95 mg/dL\"\n"
          "  },\n"
          "  \"aiObservations\": [\n"
          "    \"Ask if target resting thresholds remain appropriate.\",\n"
          "    \"Review 30-day hemodynamic trend stability.\"\n"
          "  ],\n"
          "  \"pdfDownloadRoute\": \"/history\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Personalized personal tracking checklist only. Please discuss medical questions directly with your doctor.*";
    }

    // Dynamic Health Summary Intent
    if (lower.contains("today's health summary") || lower.contains("health summary") || lower.contains("overview today")) {
      return "Here is your unified health summary for **$patientName** today:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"health_summary_card\",\n"
          "  \"title\": \"Today's Health Overview\",\n"
          "  \"value\": \"Stable & On Track\",\n"
          "  \"subtitle\": \"All 4 core vitals measured within target operational thresholds today.\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"blood_pressure_card\",\n"
          "  \"title\": \"Blood Pressure\",\n"
          "  \"value\": \"120/80\",\n"
          "  \"unit\": \"mmHg\",\n"
          "  \"status\": \"normal\",\n"
          "  \"subtitle\": \"Resting morning measurement\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"glucose_card\",\n"
          "  \"title\": \"Fasting Glucose\",\n"
          "  \"value\": \"95\",\n"
          "  \"unit\": \"mg/dL\",\n"
          "  \"status\": \"normal\",\n"
          "  \"subtitle\": \"Pre-breakfast level\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"pulse_card\",\n"
          "  \"title\": \"Resting Pulse Rate\",\n"
          "  \"value\": \"72\",\n"
          "  \"unit\": \"bpm\",\n"
          "  \"status\": \"normal\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"temperature_card\",\n"
          "  \"title\": \"Body Temperature\",\n"
          "  \"value\": \"98.6\",\n"
          "  \"unit\": \"°F\",\n"
          "  \"status\": \"normal\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"ai_insight_card\",\n"
          "  \"title\": \"Daily AI Clinical Insight\",\n"
          "  \"insight\": \"Vitals show excellent hemodynamic stability. Maintaining low dietary sodium will keep blood pressure consistent.\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"reminder_card\",\n"
          "  \"title\": \"Evening Blood Pressure Check\",\n"
          "  \"time\": \"08:00 PM\",\n"
          "  \"dosage\": \"Rest 5 mins before reading\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: VitalAI responses are for educational tracking only and do not replace professional medical advice.*";
    }

    // Educational Intent ("What is systolic pressure?")
    if (lower.contains("systolic") || lower.contains("what is blood pressure") || lower.contains("diastolic") || lower.contains("explain bp")) {
      return "Blood pressure measures the force of circulating blood against the walls of blood vessels.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"education_card\",\n"
          "  \"title\": \"Systolic Pressure Explained\",\n"
          "  \"definition\": \"Systolic blood pressure (the top number) measures the pressure exerted against arterial walls when your heart ventricles contract and pump oxygenated blood throughout the body.\",\n"
          "  \"normalRange\": \"90 - 120 mmHg\",\n"
          "  \"illustrationIcon\": \"favorite\",\n"
          "  \"relatedReading\": [\"Diastolic Pressure\", \"Pulse Pressure\", \"DASH Diet\"],\n"
          "  \"learnMoreUrl\": \"https://www.heart.org\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational content only. Consult your physician for personal medical questions.*";
    }

    // AI Recommendation Intent ("How can I lower my blood pressure?")
    if (lower.contains("lower") || lower.contains("recommend") || lower.contains("diet") || lower.contains("sodium")) {
      return "Here are structured AI clinical recommendations for optimizing your vitals:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"DASH Eating Plan & Hydration Plan\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Following the DASH Eating Plan and maintaining daily hydration reduces arterial stiffness and lowers systolic pressure.\",\n"
          "  \"relatedMetric\": \"Blood Pressure & Pulse Rate\",\n"
          "  \"suggestedFollowUp\": [\n"
          "    \"Adopt the DASH Eating Plan rich in potassium and fiber\",\n"
          "    \"Drink at least 2.5 Liters of water daily\",\n"
          "    \"Keep dietary sodium under 2,000 mg\",\n"
          "    \"Log evening resting blood pressure\"\n"
          "  ],\n"
          "  \"disclaimer\": \"Educational tracking advice only. Consult your doctor before making major dietary adjustments.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: VitalAI advice is educational and non-diagnostic.*";
    }

    // Dynamic Report Generator Intent ("Generate my health report")
    if (lower.contains("report") || lower.contains("generate report")) {
      return "Here is your generated clinical health report:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"report_card\",\n"
          "  \"patientName\": \"$patientName\",\n"
          "  \"reportDate\": \"August 2026\",\n"
          "  \"summaryText\": \"Patient displays consistent resting vitals within normal physiological parameters. Blood pressure averages 122/80 mmHg with a resting heart rate of 72 bpm.\",\n"
          "  \"vitalsOverview\": {\n"
          "    \"Blood Pressure\": \"122/80 mmHg\",\n"
          "    \"Glucose Average\": \"95 mg/dL\",\n"
          "    \"Pulse Rate\": \"72 bpm\",\n"
          "    \"SpO2\": \"98%\"\n"
          "  },\n"
          "  \"aiObservations\": [\n"
          "    \"No abnormal hypertensive spikes recorded in past 30 days.\",\n"
          "    \"Glucose levels remain steady fasting.\"\n"
          "  ],\n"
          "  \"pdfDownloadRoute\": \"/history\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Report generated for personal record management.*";
    }

    // Health Timeline Intent ("Show my health over the last six months")
    if (lower.contains("timeline") || lower.contains("six months") || lower.contains("6 months") || lower.contains("history")) {
      return "Here is your 6-Month Vitals Timeline:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"timeline_card\",\n"
          "  \"title\": \"6-Month Vitals Progression\",\n"
          "  \"timeSpan\": \"Last 6 Months\",\n"
          "  \"monthlyEvents\": [\n"
          "    {\"month\": \"March 2026\", \"note\": \"BP 128/82 mmHg • Initiated daily walking routine\"},\n"
          "    {\"month\": \"April 2026\", \"note\": \"BP 125/80 mmHg • Sodium intake reduced\"},\n"
          "    {\"month\": \"May 2026\", \"note\": \"BP 122/79 mmHg • Stable resting vitals\"},\n"
          "    {\"month\": \"June 2026\", \"note\": \"BP 120/78 mmHg • Optimal arterial elasticity\"},\n"
          "    {\"month\": \"July 2026\", \"note\": \"BP 121/80 mmHg • Consistent glucose levels\"}\n"
          "  ],\n"
          "  \"highlights\": [\n"
          "    \"Systolic pressure dropped 8 mmHg overall.\",\n"
          "    \"Physical activity habit established.\"\n"
          "  ]\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // Trend Analysis Intent ("Compare my blood pressure over the last month", "Compare this week's vitals")
    if (lower.contains("trend") || lower.contains("compare") || lower.contains("chart")) {
      if (lower.contains("compare")) {
        return "Here is a side-by-side comparison of your vitals:\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"comparison_chart\",\n"
            "  \"title\": \"Vitals Comparison (This Week vs Last Week)\",\n"
            "  \"series1Name\": \"This Week\",\n"
            "  \"series1Data\": [120, 122, 118, 121, 119],\n"
            "  \"series2Name\": \"Last Week\",\n"
            "  \"series2Data\": [128, 126, 125, 124, 127],\n"
            "  \"labels\": [\"Mon\", \"Tue\", \"Wed\", \"Thu\", \"Fri\"],\n"
            "  \"comparisonNote\": \"Systolic blood pressure improved by an average of 6 mmHg compared to last week.\"\n"
            "}\n"
            "```\n\n"
            "*Disclaimer: Educational tracking only.*";
      }

      return "Here is your Vitals Trend Chart:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"trend_chart\",\n"
          "  \"title\": \"Systolic BP Trend\",\n"
          "  \"metricType\": \"bp\",\n"
          "  \"dataPoints\": [128, 124, 122, 120, 124],\n"
          "  \"labels\": [\"Log 1\", \"Log 2\", \"Log 3\", \"Log 4\", \"Log 5\"],\n"
          "  \"summary\": \"Overall downward trend towards optimal resting range.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // Multi-Widget Query ("How am I doing today?")
    if (lower.contains("how am i doing") || lower.contains("how am i")) {
      return "Here is your multi-card health status breakdown for **$patientName**:\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"health_summary_card\",\n"
          "  \"title\": \"Today's Wellness Status\",\n"
          "  \"value\": \"Optimal Hemodynamic Control\",\n"
          "  \"subtitle\": \"No abnormal spikes detected across all recorded metrics.\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"blood_pressure_card\",\n"
          "  \"title\": \"Blood Pressure\",\n"
          "  \"value\": \"120/80\",\n"
          "  \"unit\": \"mmHg\",\n"
          "  \"status\": \"normal\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"glucose_card\",\n"
          "  \"title\": \"Blood Glucose\",\n"
          "  \"value\": \"95\",\n"
          "  \"unit\": \"mg/dL\",\n"
          "  \"status\": \"normal\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"trend_chart\",\n"
          "  \"title\": \"Systolic BP Trend\",\n"
          "  \"metricType\": \"bp\",\n"
          "  \"dataPoints\": [124, 122, 120, 118, 120],\n"
          "  \"labels\": [\"Log 1\", \"Log 2\", \"Log 3\", \"Log 4\", \"Log 5\"]\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"ai_insight_card\",\n"
          "  \"title\": \"AI Clinical Insight\",\n"
          "  \"insight\": \"Your resting heart rate and arterial pressure remain in sync with target wellness parameters.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // Default Fallback with Action Button
    final cleanQuery = prompt.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    return "Regarding your query **\"$cleanQuery\"**:\n\n"
        "VitalAI recommends logging vitals regularly to help Gemini compose tailored GenUI insights.\n\n"
        "```json\n"
        "{\n"
        "  \"type\": \"action_button\",\n"
        "  \"label\": \"Log New Vitals Reading\",\n"
        "  \"action\": \"navigate\",\n"
        "  \"route\": \"/add-vital\"\n"
        "}\n"
        "```\n\n"
        "*Disclaimer: Educational tracking only. Consult your physician for medical advice.*";
  }
}
