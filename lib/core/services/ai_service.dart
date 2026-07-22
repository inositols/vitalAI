import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/features/ai_assistant/data/models/chat_message.dart';
import 'package:vitalai/features/ai_assistant/data/models/health_context.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';

/// Service responsible for communicating with Gemini to generate context-aware health insights,
/// summarize trends, prepare doctor visits, and answer educational queries with strict compliance guardrails.
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
        systemInstruction: Content.system(_systemInstruction),
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
  void setConsent(bool consented) {
    // Deprecated: consent is now read directly from SettingsBloc.
  }

  /// Whether the user has consented to sharing data with the AI.
  bool get hasConsent {
    if (locator.isRegistered<SettingsBloc>()) {
      return locator<SettingsBloc>().state.aiConsent;
    }
    return true;
  }

  /// Check if the AI model is fully configured.
  bool get isConfigured => _model != null;

  /// Generate response from a chat query using patient health context.
  Future<String> askAssistant(
    String prompt, {
    HealthContext? healthContext,
    List<ChatMessage>? history,
  }) async {
    if (!hasConsent) {
      return "Consent Required: Please enable AI sharing in your settings before asking the AI assistant.";
    }

    // Check emergency crisis triggers first
    final emergencyCheck = _checkEmergencyInput(prompt, healthContext);
    if (emergencyCheck != null) {
      return emergencyCheck;
    }

    if (_model == null) {
      return _generateMockFallback(prompt, healthContext);
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
      return response.text ??
          "I was unable to analyze the data. Please try again.";
    } catch (e) {
      debugPrint("Gemini API Error: $e");
      return _generateMockFallback(prompt, healthContext);
    }
  }

  /// Generate Quick Health Overview Action
  Future<String> generateHealthSummary(HealthContext healthContext) async {
    const prompt =
        "Generate a comprehensive health summary based on my health context. Include:\n"
        "1. Recent Health Overview\n"
        "2. Positive Changes & Progress\n"
        "3. Key Areas to Monitor";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Vital Analysis Action
  Future<String> generateVitalAnalysis(
    HealthContext healthContext, {
    String? targetVital,
  }) async {
    final target = targetVital ?? "Blood pressure, Glucose, Pulse rate, SpO₂";
    final prompt =
        "Provide a detailed vital analysis for $target based on my recorded health records.";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Doctor Preparation Action
  Future<String> generateDoctorPrep(HealthContext healthContext) async {
    const prompt =
        "Prepare a doctor visit summary based on my recent health records. Include:\n"
        "1. Important Vitals Trends\n"
        "2. Summary of Symptoms/Concerns\n"
        "3. Top 3 Questions to Ask My Doctor";
    return askAssistant(prompt, healthContext: healthContext);
  }

  /// Generate Quick Health Report Explanation
  Future<String> explainReport(
    String reportText,
    HealthContext healthContext,
  ) async {
    final prompt =
        "Explain this health report summary in clear, simple terms for me:\n\n$reportText";
    return askAssistant(prompt, healthContext: healthContext);
  }

  // ==========================================
  // Compliance Preamble & System Instruction
  // ==========================================
  static const String _systemInstruction = """
You are VitalAI, a personalized context-aware health assistant.
Your goal is to explain health vitals, clarify medical terms, analyze historical trends, and prepare doctor visit notes based on the patient's health context payload.

HEALTHCARE SAFETY GUIDELINES & COMPLIANCE RULES:
1. NEVER diagnose any disease, illness, or medical condition. Use phrases like "Your readings appear elevated" or "Consider discussing with a healthcare provider".
2. NEVER claim absolute medical certainty. State possibilities and trends clearly without definitive assertions.
3. NEVER prescribe, recommend, or adjust any medication, dosage, or medical treatment.
4. ALWAYS explain information clearly in accessible, simple language.
5. ALWAYS recommend consulting a qualified healthcare professional (doctor, nurse) for any health concerns or formal diagnosis.
6. DETECT EMERGENCY VALUES and respond with high-priority emergency alerts recommending immediate emergency care (call 911 or visit ER) if:
   - Blood Pressure: Systolic >= 180 mmHg or Diastolic >= 120 mmHg (Hypertensive Crisis).
   - Oxygen Saturation (SpO2): < 90% (Severe Hypoxia).
   - Blood Glucose: < 50 mg/dL (Severe Hypoglycemia) or > 300 mg/dL with symptoms (Severe Hyperglycemia).
   - Body Temperature: > 104°F (40°C) or < 95°F (35°C) (Severe fever/hypothermia).
""";

  String? _checkEmergencyInput(String prompt, HealthContext? context) {
    final lower = prompt.toLowerCase();
    if (lower.contains("180") ||
        lower.contains("120") ||
        lower.contains("crisis") ||
        lower.contains("emergency") ||
        lower.contains("chest pain") ||
        lower.contains("shortness of breath")) {
      return "⚠️ **IMPORTANT EMERGENCY NOTICE:** Your query or readings indicate potentially critical values. A systolic blood pressure of 180 mmHg or higher, or diastolic of 120 mmHg or higher, can signal a hypertensive crisis. Severe chest pain or difficulty breathing requires urgent attention. Please seek immediate emergency medical care or call emergency services (911). *Do not wait to see if symptoms decrease.*";
    }

    if (context != null) {
      if (context.hasBpData) {
        if ((context.bpSystolicTrend.highest ?? 0) >= 180 ||
            (context.bpDiastolicTrend.highest ?? 0) >= 120) {
          return "⚠️ **CRITICAL BLOOD PRESSURE ALERT:** Your recorded vitals include blood pressure readings of **${context.bpSystolicTrend.highest?.toInt()}/${context.bpDiastolicTrend.highest?.toInt()} mmHg**, which reaches Hypertensive Crisis levels. Please seek emergency medical evaluation immediately.";
        }
      }
      if (context.hasSpo2Data && (context.spo2Trend.lowest ?? 100) < 90) {
        return "⚠️ **CRITICAL OXYGEN SATURATION ALERT:** Your oxygen saturation (SpO₂) dropped below 90% (${context.spo2Trend.lowest?.toStringAsFixed(1)}%). Severe hypoxia requires prompt emergency medical attention.";
      }
    }
    return null;
  }

  // ==========================================
  // Context-Aware Offline Fallback Mode
  // ==========================================
  String _generateMockFallback(String prompt, HealthContext? context) {
    final lower = prompt.toLowerCase();

    // 1. Specific Context Queries
    if (lower.contains("blood pressure") || lower.contains("bp")) {
      if (context != null && context.hasBpData) {
        final sysAvg = context.bpSystolicTrend.average?.toStringAsFixed(0) ?? '124';
        final diaAvg = context.bpDiastolicTrend.average?.toStringAsFixed(0) ?? '82';
        final direction = context.bpSystolicTrend.direction.toLowerCase();
        return "Based on your recorded readings over the recent window, your average blood pressure is **$sysAvg/$diaAvg mmHg**. Your readings have been **$direction** compared to previous weeks.\n\n"
            "**Key BP Highlights:**\n"
            "- Systolic Highest: ${context.bpSystolicTrend.highest?.toStringAsFixed(0) ?? 'N/A'} mmHg\n"
            "- Systolic Lowest: ${context.bpSystolicTrend.lowest?.toStringAsFixed(0) ?? 'N/A'} mmHg\n\n"
            "*Disclaimer: This analysis is for educational tracking and does not constitute a clinical diagnosis. Consider sharing these trends with your physician.*";
      } else {
        return "Based on general guidelines, a normal blood pressure reading for adults is typically under **120/80 mmHg**. Log your blood pressure regularly in VitalAI to generate personalized trend analysis.\n\n"
            "*Disclaimer: Educational tracking only. Consult a healthcare provider for diagnosis.*";
      }
    }

    if (lower.contains("glucose") || lower.contains("sugar")) {
      if (context != null && context.hasGlucoseData) {
        final avg = context.glucoseTrend.average?.toStringAsFixed(1) ?? '105';
        final direction = context.glucoseTrend.direction.toLowerCase();
        return "Based on your recorded readings, your average blood glucose is **$avg mg/dL**. Your glucose pattern appears **$direction**.\n\n"
            "**Glucose Overview:**\n"
            "- Highest: ${context.glucoseTrend.highest?.toStringAsFixed(1)} mg/dL\n"
            "- Lowest: ${context.glucoseTrend.lowest?.toStringAsFixed(1)} mg/dL\n\n"
            "*Disclaimer: Educational tracking only. Please discuss blood glucose patterns with your endocrinologist or PCP.*";
      } else {
        return "Normal fasting blood glucose for non-diabetic adults is generally between **70 and 99 mg/dL**. Log your glucose readings to unlock tailored pattern tracking.\n\n"
            "*Disclaimer: Educational tracking only.*";
      }
    }

    if (lower.contains("summarise") || lower.contains("summary") || lower.contains("overview")) {
      if (context != null && context.hasVitalsData) {
        final buffer = StringBuffer();
        buffer.writeln("📊 **Personalized Health Overview for ${context.patientName}**\n");
        buffer.writeln("**Recent Vitals Status:**");
        if (context.hasBpData) {
          buffer.writeln("- **Blood Pressure:** Avg ${context.bpSystolicTrend.average?.toStringAsFixed(0)}/${context.bpDiastolicTrend.average?.toStringAsFixed(0)} mmHg (${context.bpSystolicTrend.direction})");
        }
        if (context.hasGlucoseData) {
          buffer.writeln("- **Blood Glucose:** Avg ${context.glucoseTrend.average?.toStringAsFixed(1)} mg/dL (${context.glucoseTrend.direction})");
        }
        if (context.hasPulseData) {
          buffer.writeln("- **Heart Rate:** Avg ${context.pulseTrend.average?.toStringAsFixed(0)} BPM");
        }
        if (context.hasSpo2Data) {
          buffer.writeln("- **SpO₂:** Avg ${context.spo2Trend.average?.toStringAsFixed(1)}%");
        }
        if (context.hasMedications) {
          buffer.writeln("\n**Current Medications:** ${context.medications.join(', ')}");
        }
        buffer.writeln("\n**Areas to Monitor:** Continue consistent daily recordings to identify long-term patterns.");
        buffer.writeln("\n*Disclaimer: VitalAI responses are for tracking purposes only and do not replace professional medical advice.*");
        return buffer.toString();
      }
    }

    if (lower.contains("doctor") || lower.contains("prepare") || lower.contains("visit")) {
      if (context != null) {
        final buffer = StringBuffer();
        buffer.writeln("📋 **Doctor Visit Preparation Notes for ${context.patientName}**\n");
        buffer.writeln("**1. Summary of Recent Readings:**");
        if (context.hasBpData) {
          buffer.writeln("- Blood Pressure Average: ${context.bpSystolicTrend.average?.toStringAsFixed(0)}/${context.bpDiastolicTrend.average?.toStringAsFixed(0)} mmHg (Max: ${context.bpSystolicTrend.highest?.toStringAsFixed(0)}/${context.bpDiastolicTrend.highest?.toStringAsFixed(0)})");
        }
        if (context.hasGlucoseData) {
          buffer.writeln("- Glucose Average: ${context.glucoseTrend.average?.toStringAsFixed(1)} mg/dL");
        }
        buffer.writeln("\n**2. Key Questions to Ask Your Doctor:**");
        buffer.writeln("- Are my current vital trends within my target personal health goal range?");
        buffer.writeln("- Should we adjust any monitoring schedules or diet guidelines based on these trends?");
        if (context.hasMedications) {
          buffer.writeln("- Are there any potential side effects or adherence considerations for my current medications (${context.medications.join(', ')})?");
        } else {
          buffer.writeln("- Are any lifestyle modifications recommended for my vital profile?");
        }
        buffer.writeln("\n*Disclaimer: Bring your raw logs or exported PDF summary to your consultation.*");
        return buffer.toString();
      }
    }

    if (lower.contains("report") || lower.contains("explain")) {
      return "📑 **Health Report Summary Explanation**\n\n"
          "Your health report aggregates your recorded blood pressure, blood glucose, temperature, pulse rate, oxygen saturation, and body weight logs over the selected date range.\n\n"
          "**Key takeaways:**\n"
          "- Stable vital patterns indicate good day-to-day consistency.\n"
          "- Fluctuations during stressful periods or after meals are normal baseline variations.\n\n"
          "*Disclaimer: This summary is generated for educational tracking and does not constitute medical advice or diagnosis.*";
    }

    if (lower.contains("medication") || lower.contains("adherence")) {
      if (context != null && context.hasMedications) {
        return "💊 **Medication Overview for ${context.patientName}**\n\n"
            "**Active Medications:**\n${context.medications.map((m) => '• $m').join('\n')}\n\n"
            "**Adherence Recommendation:** Take medications at consistent daily times as prescribed by your physician. Contact your healthcare provider before stopping or changing any doses.\n\n"
            "*Disclaimer: VitalAI does not prescribe or alter medication regimens.*";
      }
    }

    // Default friendly response using patient name if context exists
    final patientName = context?.patientName ?? 'there';
    return "Hello $patientName! Based on your health profile, I am ready to answer questions about your blood pressure, glucose, pulse rate, SpO₂, temperature, or doctor visit preparations.\n\n"
        "Try asking:\n"
        "- *\"How has my blood pressure changed recently?\"*\n"
        "- *\"Summarise my health this week\"*\n"
        "- *\"Prepare questions for my doctor\"*\n\n"
        "*Disclaimer: VitalAI responses are for educational tracking only and do not replace professional medical advice.*";
  }
}
