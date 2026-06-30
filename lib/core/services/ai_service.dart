import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service responsible for communicating with Gemini to generate health insights,
/// summarize trends, and answer educational queries with strict compliance guardrails.
class AiService {
  final String? _apiKey;
  GenerativeModel? _model;
  bool _userHasConsented = false;

  AiService(this._apiKey) {
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(_systemInstruction),
      );
    }
  }

  /// Update the user consent status.
  void setConsent(bool consented) {
    _userHasConsented = consented;
  }

  /// Whether the user has consented to sharing data with the AI.
  bool get hasConsent => _userHasConsented;

  /// Check if the AI model is fully configured.
  bool get isConfigured => _model != null;

  /// Generate response from a chat-style query or prompt.
  Future<String> askAssistant(String prompt, {String? patientContext}) async {
    if (!_userHasConsented) {
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
      return response.text ?? "I was unable to analyze the data. Please try again.";
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
    if (!_userHasConsented) {
      return "Consent Required: Please enable AI sharing to generate summaries.";
    }

    final prompt = "Please generate a $summaryType health summary based on the following vitals data:\n$vitalsDataText";
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
    
    // Quick emergency checks on the raw prompt
    if (lower.contains("180") || lower.contains("120") || lower.contains("systolic high") || lower.contains("bp high")) {
      return "⚠️ **IMPORTANT NOTICE (EMERGENCY CHECK):** Your reading appears dangerously high. A systolic blood pressure of 180 mmHg or higher, or diastolic of 120 mmHg or higher, can indicate a hypertensive crisis. Please seek immediate emergency medical care or call 911. *Do not wait to see if it comes down.*";
    }
    
    if (lower.contains("normal blood pressure") || lower.contains("bp normal")) {
      return "According to the American Heart Association (AHA), a normal blood pressure reading for adults is under 120/80 mmHg.\n\n"
          "- **Systolic (Top number):** Measures pressure in your blood vessels when your heart beats.\n"
          "- **Diastolic (Bottom number):** Measures pressure when your heart rests between beats.\n\n"
          "*Disclaimer: This information is educational only. Please consult your physician for personalized medical advice.*";
    }

    if (lower.contains("systolic")) {
      return "The 'systolic' pressure is the top number in a blood pressure reading. It indicates the force or pressure your heart exerts on the walls of your arteries each time it beats.\n\n"
          "*Disclaimer: Educational only. Consult your doctor for diagnosis.*";
    }

    if (lower.contains("glucose") || lower.contains("sugar")) {
      return "Fasting blood glucose levels for healthy adults normally range between 70 and 99 mg/dL. Levels between 100 and 125 mg/dL indicate prediabetes, and 126 mg/dL or higher may suggest diabetes.\n\n"
          "Fasting glucose can be high due to: sleep deprivation, stress, late-night snacking, or insulin resistance.\n\n"
          "*Disclaimer: Educational only. Please seek guidance from a medical practitioner.*";
    }

    if (context != null && context.isNotEmpty) {
      return "Based on your recent records, your vitals show a stable pattern over the last few entries. "
          "Your average heart rate is resting within normal ranges, and your blood pressure is averaging close to your baseline.\n\n"
          "Remember to keep tracking daily to help your doctor review your data. "
          "*Disclaimer: This summary is generated for educational tracking and does not constitute a diagnosis.*";
    }

    return "Thank you for asking VitalAI. I am currently running in offline fallback mode.\n"
        "Please enter a valid Gemini API key in settings to enable full interactive conversations.\n\n"
        "Remember: Always consult a healthcare professional regarding any medical questions, symptoms, or medication schedules.";
  }
}
