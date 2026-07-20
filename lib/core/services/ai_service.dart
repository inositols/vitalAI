import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';

/// Service responsible for communicating with Gemini to generate health insights,
/// summarize trends, and answer educational queries with strict compliance guardrails.
class AiService {
  String? _apiKey;
  GenerativeModel? _model;

  AiService(this._apiKey) {
    _initModel();
  }

  void _initModel() {
    final isPlaceholder = _apiKey == null ||
        _apiKey!.isEmpty ||
        _apiKey == 'AQ.Ab8RN6LA8ZZoVJVfyguJa_MyO1far3K4BVgHVOXJ-4WThfFkrA';

    if (!isPlaceholder) {
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
  bool get hasConsent => locator<SettingsBloc>().state.aiConsent;

  /// Check if the AI model is fully configured.
  bool get isConfigured => _model != null;

  /// Generate response from a chat-style query or prompt.
  Future<String> askAssistant(String prompt, {String? patientContext}) async {
    if (!hasConsent) {
      return "Consent Required: Please enable AI sharing in your settings before asking the AI assistant.";
    }

    if (_model == null) {
      return _generateMockFallback(prompt, patientContext);
    }

    try {
      final inputPrompt = patientContext != null
          ? "Patient History Context:\n$patientContext\n\nUser Question: $prompt"
          : prompt;

      final content = [Content.text(inputPrompt)];
      final response = await _model!.generateContent(content);
      return response.text ??
          "I was unable to analyze the data. Please try again.";
    } catch (e) {
      debugPrint("Gemini API Error: $e");
      return "An error occurred while contacting the AI assistant. (Running offline/fallback mode).\n\n"
          "${_generateMockFallback(prompt, patientContext)}";
    }
  }

  /// Generate daily/weekly smart health summaries.
  Future<String> generateSummary({
    required String summaryType, // 'daily' or 'weekly'
    required String vitalsDataText,
  }) async {
    if (!hasConsent) {
      return "Consent Required: Please enable AI sharing to generate summaries.";
    }

    final prompt =
        "Please generate a $summaryType health summary based on the following vitals data:\n$vitalsDataText";
    return askAssistant(prompt);
  }

  // ==========================================
  // Compliance Preamble & System Instruction
  // ==========================================
  static const String _systemInstruction = """
You are VitalAI, a secure health companion AI assistant. Your goal is to explain health vitals readings, clarify medical terms, answer health education questions, summarize trends, and generate doctor visit summaries based on patient-provided records.

CRITICAL MEDICAL COMPLIANCE RULES:
1. NEVER diagnose any disease, illness, or condition.
2. NEVER prescribe, recommend, or adjust any medication, dosage, or medical treatment.
3. ALWAYS remind the user that your explanation is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.
4. ALWAYS recommend that the user consult a qualified healthcare professional (doctor, nurse) for any health concerns.
5. DETECT EMERGENCY VALUES and respond with immediate high-visibility warnings recommending emergency care (911 or nearest ER) if the following critical readings are present:
   - Blood Pressure: Systolic >= 180 mmHg or Diastolic >= 120 mmHg (Hypertensive Crisis).
   - Oxygen Saturation (SpO2): < 90% (Severe Hypoxia).
   - Blood Glucose: < 50 mg/dL (Severe Hypoglycemia) or > 300 mg/dL with symptoms (Severe Hyperglycemia).
   - Body Temperature: > 104°F (40°C) or < 95°F (35°C) (Severe fever/hypothermia).
""";

  // ==========================================
  // Mock Fallback Mode (For offline/missing API key)
  // ==========================================
  String _generateMockFallback(String prompt, String? context) {
    final lower = prompt.toLowerCase();

    // 1. Emergency Crisis Alert Checks
    if (lower.contains("180") ||
        lower.contains("120") ||
        lower.contains("crisis") ||
        lower.contains("emergency") ||
        lower.contains("chest pain") ||
        lower.contains("shortness of breath")) {
      return "⚠️ **IMPORTANT NOTICE (EMERGENCY CHECK):** Your readings or symptoms appear dangerously high. A systolic blood pressure of 180 mmHg or higher, or diastolic of 120 mmHg or higher, can indicate a hypertensive crisis. Please seek immediate emergency medical care or call 911. *Do not wait to see if it comes down.*";
    }

    // 2. Terminology definitions / General education
    if (lower.contains("systolic")) {
      if (lower.contains("mean") || lower.contains("what") || lower.contains("define") || lower.contains("explain") || lower.contains("is")) {
        return "🩺 **What is Systolic Pressure?**\n\n"
            "**Systolic pressure** (the top/first number in a blood pressure reading) measures the force that your heart exerts on the walls of your arteries each time it contracts to pump blood to the body.\n\n"
            "For example, in a reading of **120/80 mmHg**, **120** is the systolic pressure. A healthy systolic pressure is typically under 120 mmHg.\n\n"
            "*Disclaimer: This explanation is for educational purposes only and does not constitute medical advice or diagnosis.*";
      }
    }

    if (lower.contains("diastolic")) {
      if (lower.contains("mean") || lower.contains("what") || lower.contains("define") || lower.contains("explain") || lower.contains("is")) {
        return "🩺 **What is Diastolic Pressure?**\n\n"
            "**Diastolic pressure** (the bottom/second number in a blood pressure reading) measures the force of blood against your artery walls when your heart rests between beats.\n\n"
            "For example, in a reading of **120/80 mmHg**, **80** is the diastolic pressure. A healthy diastolic pressure is typically under 80 mmHg.\n\n"
            "*Disclaimer: This explanation is for educational purposes only and does not constitute medical advice or diagnosis.*";
      }
    }

    if (lower.contains("blood pressure") || lower.contains("bp")) {
      if (lower.contains("normal") || lower.contains("what") || lower.contains("mean") || lower.contains("define") || lower.contains("explain")) {
        return "🩺 **Understanding Blood Pressure**\n\n"
            "Blood pressure is recorded as two numbers, representing the pressure inside your arteries:\n"
            "1. **Systolic Pressure** (top number): The pressure when the heart beats.\n"
            "2. **Diastolic Pressure** (bottom number): The pressure when the heart rests between beats.\n\n"
            "**General guidelines for adults:**\n"
            "- **Normal:** Under 120/80 mmHg\n"
            "- **Elevated:** 120-129 / under 80 mmHg\n"
            "- **High Blood Pressure (Stage 1):** 130-139 / 80-89 mmHg\n"
            "- **High Blood Pressure (Stage 2):** 140 or higher / 90 or higher mmHg\n\n"
            "*Disclaimer: This information is for educational purposes only. Always consult a healthcare professional for diagnosis or treatment.*";
      }
    }

    if (lower.contains("glucose") || lower.contains("sugar") || lower.contains("diabetes")) {
      if (lower.contains("fasting") || lower.contains("high") || lower.contains("why") || lower.contains("what") || lower.contains("mean")) {
        return "🩸 **Fasting Glucose & Blood Sugar**\n\n"
            "Fasting glucose is blood sugar measured after not eating for at least 8 hours. High fasting glucose (hyperglycemia) can be caused by several factors:\n"
            "- **Insulin Resistance:** Cells don't respond well to insulin, leaving glucose in the bloodstream.\n"
            "- **Dawn Phenomenon:** Natural release of hormones (like cortisol) in the early morning increases glucose release from the liver.\n"
            "- **Diet & Lifestyle:** Heavy late-night meals, lack of physical activity, or high stress levels.\n\n"
            "**Reference ranges:**\n"
            "- **Normal:** 70 to 99 mg/dL\n"
            "- **Prediabetes:** 100 to 125 mg/dL\n"
            "- **Diabetes:** 126 mg/dL or higher on two separate tests\n\n"
            "*Disclaimer: This is for educational tracking and does not constitute a medical diagnosis. Please consult your physician for clinical advice.*";
      }
    }

    if (lower.contains("oxygen") || lower.contains("spo2") || lower.contains("hypoxia")) {
      if (lower.contains("what") || lower.contains("mean") || lower.contains("define") || lower.contains("explain") || lower.contains("normal")) {
        return "🫁 **Oxygen Saturation (SpO2)**\n\n"
            "**SpO2** measures the percentage of oxygen-carrying hemoglobin in your blood relative to the maximum amount it can carry.\n\n"
            "**Reference ranges:**\n"
            "- **Normal:** 95% to 100%\n"
            "- **Low (Hypoxia):** Below 90% (requires immediate clinical attention)\n\n"
            "*Disclaimer: This is for educational tracking. Consult a medical professional for respiratory concerns.*";
      }
    }

    if (lower.contains("fever") || lower.contains("temp") || lower.contains("temperature")) {
      if (lower.contains("what") || lower.contains("mean") || lower.contains("define") || lower.contains("explain") || lower.contains("normal")) {
        return "🌡️ **Body Temperature & Fever**\n\n"
            "Normal body temperature typically centers around **37°C (98.6°F)**, though it naturally fluctuates throughout the day.\n\n"
            "**Reference ranges:**\n"
            "- **Normal range:** 36.1°C to 37.2°C (97°F to 99°F)\n"
            "- **Fever:** 38°C (100.4°F) or higher (usually signals the body is fighting an infection)\n"
            "- **High Fever:** Above 39.4°C (103°F)\n\n"
            "*Disclaimer: This is for educational tracking. Seek immediate medical assistance for high, persistent fevers.*";
      }
    }

    if (lower.contains("pulse") || lower.contains("heart rate") || lower.contains("bpm")) {
      if (lower.contains("what") || lower.contains("mean") || lower.contains("define") || lower.contains("explain") || lower.contains("normal")) {
        return "💓 **Heart Rate & Pulse**\n\n"
            "Your **heart rate** (pulse) is the number of times your heart beats per minute (BPM).\n\n"
            "**Reference ranges for resting adults:**\n"
            "- **Normal:** 60 to 100 BPM\n"
            "- **Athletic resting:** Can be as low as 40 to 60 BPM\n"
            "- **Tachycardia (High):** Over 100 BPM\n"
            "- **Bradycardia (Low):** Under 60 BPM\n\n"
            "*Disclaimer: This is for educational tracking. Consult a doctor for any cardiovascular concerns.*";
      }
    }

    // 3. Personalized user summary/baseline query
    if (lower.contains("my") || lower.contains("me") || lower.contains("history") || lower.contains("baseline") || lower.contains("records") || lower.contains("vitals") || lower.contains("context") || lower.contains("summary")) {
      String contextSummary = "No patient context is currently selected or loaded.";
      if (context != null && context.isNotEmpty && !context.contains("No patient context available")) {
        contextSummary = "Based on your active patient profile, here is your current baseline info:\n\n$context";
      }
      return "📊 **Active Patient Profile & Records Summary**\n\n"
          "$contextSummary\n\n"
          "To get detailed insights, ensure you have input your daily vitals in the dashboard. Connect a valid Gemini API key in settings for personalized, dynamic analysis of your historical health trends.\n\n"
          "*Disclaimer: This summary is generated for educational tracking and does not constitute medical advice or a formal diagnosis.*";
    }

    // 4. Default keyword matches
    if (lower.contains("hello") || lower.contains("hi") || lower.contains("hey")) {
      return "Hello! I am your VitalAI Health Education assistant. I can help explain your vitals (blood pressure, blood glucose, temperature, etc.) and suggest healthy lifestyle tips. What would you like to discuss today?";
    }

    if (lower.contains("thank") || lower.contains("thanks")) {
      return "You're very welcome! Remember to keep logging your vitals regularly to build a rich history for your doctor's review.";
    }

    // 5. General match if nothing specific caught (but fallback still matches some categories)
    if (lower.contains("blood pressure") || lower.contains("bp")) {
      return "Normal blood pressure for adults is defined as under 120/80 mmHg. To manage blood pressure: maintain a low-sodium diet, exercise regularly, and reduce stress.\n\n"
          "*Disclaimer: This is for educational tracking and does not constitute medical diagnosis.*";
    }
    if (lower.contains("glucose") || lower.contains("sugar") || lower.contains("diabetes")) {
      return "Normal fasting blood glucose is between 70 and 99 mg/dL. Consider monitoring your carbohydrate intake, sleeping well, and drinking plenty of water.\n\n"
          "*Disclaimer: This is for educational tracking and does not constitute medical diagnosis.*";
    }

    return "Thank you for asking VitalAI. You asked: \"$prompt\"\n\n"
        "To learn more about this health topic, connect a valid Gemini API key in settings to enable full interactive conversations with live AI insights. Otherwise, try asking about terminology like **systolic**, **diastolic**, **blood pressure**, **glucose**, or select one of the quick question chips below.\n\n"
        "*Disclaimer: VitalAI educational responses are for tracking purposes only and do not replace professional medical advice.*";
  }
}
