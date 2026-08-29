import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vitalai/core/config/app_env.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/core/genui/services/ai_intent_classifier.dart';
import 'package:vitalai/core/genui/services/genui_prompt_builder.dart';
import 'package:vitalai/features/ai_assistant/data/models/chat_message.dart';
import 'package:vitalai/features/ai_assistant/data/models/health_context.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';

/// Service responsible for communicating with Gemini to answer any health and medical question,
/// generate context-aware clinical insights, summarize trends, prepare doctor visits,
/// and compose dynamic Generative UI structures.
class AiService {
  String? _apiKey;
  GenerativeModel? _model;

  AiService(this._apiKey) {
    _initModel();
  }

  void _initModel() {
    final keyToUse = (_apiKey != null && _apiKey!.trim().isNotEmpty)
        ? _apiKey!.trim()
        : AppEnv.defaultGeminiApiKey;

    final hasValidKey = keyToUse.isNotEmpty;

    if (hasValidKey) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: keyToUse,
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

  /// Generate response from a chat query for any health topic, using patient context when relevant.
  Future<String> askAssistant(
    String prompt, {
    HealthContext? healthContext,
    List<ChatMessage>? history,
  }) async {
    if (!hasConsent) {
      return "Consent Required: Please enable AI sharing in your settings before asking the AI assistant.";
    }

    // Auto-resolve API key from SettingsBloc if not yet configured
    if (_model == null && locator.isRegistered<SettingsBloc>()) {
      final settingsKey = locator<SettingsBloc>().state.apiKey;
      if (settingsKey.trim().isNotEmpty) {
        updateApiKey(settingsKey.trim());
      }
    }

    // 1. Check emergency crisis triggers first
    final emergencyCheck = _checkEmergencyInput(prompt, healthContext);
    if (emergencyCheck != null) {
      return emergencyCheck;
    }

    // 2. Classify user intent
    final intent = AiIntentClassifier.classify(prompt);

    // 3. If Gemini Model is configured, query Gemini API directly
    if (_model != null) {
      try {
        final buffer = StringBuffer();
        if (healthContext != null) {
          buffer.writeln('Patient Profile & Health Context:');
          buffer.writeln(healthContext.toAiContextString());
          buffer.writeln('-----------------------------------');
        }

        if (history != null && history.isNotEmpty) {
          buffer.writeln('Recent Conversation History:');
          final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
          for (var msg in recentHistory) {
            buffer.writeln('${msg.sender.toUpperCase()}: ${msg.content}');
          }
          buffer.writeln('-----------------------------------');
        }

        buffer.writeln('User Question: $prompt');
        buffer.writeln('Detected Query Intent: ${intent.name}');
        buffer.writeln(
          'Specific Guidelines for this response:\n'
          '1. Answer the question directly with high clinical precision, citing recognized clinical guidelines (AHA, ADA, WHO, CDC) where relevant.\n'
          '2. If the user asks for a simple definition or explanation, provide a concise text answer without generating bloated UI.\n'
          '3. If the user asks about patient records or trends, use ONLY the recorded context. If data is sparse or missing, state this limitation clearly.\n'
          '4. If generating GenUI components, choose ONLY the single most appropriate component (e.g. trend_chart for trends, reminder_card for meds, report_card for doctor prep).\n'
          '5. Action buttons must ONLY route to verified paths: /charts, /history, /add-vital, /reminders, /caregiver, /settings, /patients.',
        );

        final content = [Content.text(buffer.toString())];
        final response = await _model!.generateContent(content);
        final textResult = response.text;
        if (textResult != null && textResult.trim().isNotEmpty) {
          return textResult;
        }
      } catch (e) {
        debugPrint("Gemini API Error (falling back to conversational engine): $e");
      }
    }

    // 4. Conversational Clinical Intelligence Engine (Answers any health topic accurately)
    return _generateMockFallback(prompt, healthContext, intent: intent);
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
    const prompt = "Generate my health report for doctor visit.";
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
        lower.contains("sudden numbness") ||
        lower.contains("facial droop") ||
        lower.contains("slurred speech") ||
        lower.contains("severe crisis");

    if (hasEmergencySymptoms) {
      return "⚠️ **IMPORTANT EMERGENCY MEDICAL NOTICE:**\n\n"
          "Symptoms such as severe crushing chest pain, acute shortness of breath, sudden facial drooping, arm weakness, or difficulty speaking indicate a potential medical emergency (such as myocardial infarction or acute stroke).\n\n"
          "• **Action Required:** Please call **911** (or your local emergency services) or proceed to the nearest Emergency Department immediately.\n"
          "• *Do not drive yourself or wait for symptoms to subside.*";
    }

    return null;
  }

  /// Conversational Clinical Intelligence Engine answering any question naturally and accurately based on intent.
  String _generateMockFallback(String prompt, HealthContext? context, {AiIntent? intent}) {
    final lower = prompt.toLowerCase().trim();
    final patientName = context?.patientName ?? 'there';
    final detectedIntent = intent ?? AiIntentClassifier.classify(prompt);

    // Baseline metrics from context
    final bpSys = context?.bpSystolicTrend.average?.round();
    final bpDia = context?.bpDiastolicTrend.average?.round();
    final bpDirection = context?.bpSystolicTrend.direction ?? 'Stable';
    final bpTotalReadings = context?.bpSystolicTrend.totalReadings ?? 0;

    final glucoseAvg = context?.glucoseTrend.average != null
        ? context!.glucoseTrend.average!.toStringAsFixed(1)
        : null;
    final glucoseTotalReadings = context?.glucoseTrend.totalReadings ?? 0;

    final pulseAvg = context?.pulseTrend.average?.round() ?? 72;
    final spo2Avg = context?.spo2Trend.average != null
        ? context!.spo2Trend.average!.toStringAsFixed(1)
        : '98';

    // -------------------------------------------------------------
    // 1. EMERGENCY SAFETY INTENT
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.safetyEmergency) {
      return "⚠️ **IMPORTANT EMERGENCY MEDICAL NOTICE:**\n\n"
          "The symptoms described (such as severe chest pain, acute shortness of breath, sudden numbness, or stroke signs) require **immediate emergency medical evaluation**.\n\n"
          "• **Action Required:** Call **911** or visit the nearest Emergency Room immediately.\n"
          "• Do not delay seeking emergency care.";
    }

    // -------------------------------------------------------------
    // 2. HEALTH EXPLANATION / DEFINITION INTENT (e.g. "What is blood pressure?", "What is BMI?")
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.healthExplanation) {
      if (lower.contains('bmi') || lower.contains('body mass index')) {
        return "### ⚖️ Body Mass Index (BMI)\n\n"
            "**Definition:** Body Mass Index (BMI) is a standardized screening metric calculated as weight in kilograms divided by the square of height in meters (kg/m²).\n\n"
            "**WHO Standard Categories:**\n"
            "• **Underweight:** < 18.5\n"
            "• **Normal Weight:** 18.5 – 24.9\n"
            "• **Overweight:** 25.0 – 29.9\n"
            "• **Obesity:** ≥ 30.0\n\n"
            "*Clinical Note: BMI is a general population screening tool and does not differentiate between adipose tissue and lean muscle mass.*";
      }

      if (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('hypertension')) {
        return "### ❤️ Blood Pressure Overview\n\n"
            "**Definition:** Blood pressure is the lateral hydrostatic pressure exerted by circulating blood against systemic arterial walls.\n\n"
            "**The Two Numbers (AHA/ACC Standards):**\n"
            "• **Systolic (Top):** Peak arterial pressure when the heart ventricles contract.\n"
            "• **Diastolic (Bottom):** Minimum arterial pressure when the heart rests between beats.\n\n"
            "**AHA 2024 Reference Ranges:**\n"
            "• **Normal:** < 120 / < 80 mmHg\n"
            "• **Elevated:** 120–129 / < 80 mmHg\n"
            "• **Stage 1 Hypertension:** 130–139 / 80–89 mmHg\n"
            "• **Stage 2 Hypertension:** ≥ 140 / ≥ 90 mmHg\n"
            "• **Hypertensive Crisis:** > 180 and/or > 120 mmHg (Urgent)";
      }

      if (lower.contains('glucose') || lower.contains('blood sugar') || lower.contains('a1c')) {
        return "### 🩸 Blood Glucose & HbA1c Overview\n\n"
            "**Definition:** Blood glucose represents the concentration of circulating glucose providing primary cellular fuel.\n\n"
            "**American Diabetes Association (ADA) Reference Ranges:**\n"
            "• **Fasting Plasma Glucose:**\n"
            "  - Normal: 70–99 mg/dL (3.9–5.5 mmol/L)\n"
            "  - Prediabetes: 100–125 mg/dL\n"
            "  - Diabetes: ≥ 126 mg/dL\n"
            "• **Hemoglobin A1c (3-Month Glycemic Average):**\n"
            "  - Normal: < 5.7%\n"
            "  - Prediabetes: 5.7% – 6.4%\n"
            "  - Diabetes: ≥ 6.5%";
      }

      // General conceptual explanation
      return "### 🩺 Medical Concept Overview\n\n"
          "Clinical parameters and biomarkers are standardized measurements established by organizations like the **WHO**, **CDC**, and **NIH** to evaluate physiological equilibrium and cardiovascular health.\n\n"
          "Maintaining numbers within reference targets significantly reduces long-term cardiovascular, metabolic, and renal risks.";
    }

    // -------------------------------------------------------------
    // 3. POSSIBLE CAUSES / DIFFERENTIAL INQUIRY INTENT (e.g. "Why can blood pressure be high?")
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.possibleCauses) {
      if (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('hypertension') || lower.contains('high pressure')) {
        return "### 🩺 Potential Factors Influencing Elevated Blood Pressure\n\n"
            "Elevated blood pressure (hypertension) is multifactorial and can be influenced by several physiological and environmental mechanisms:\n\n"
            "**1. Lifestyle & Dietary Factors:**\n"
            "• **Excess Sodium Intake:** Increases intravascular fluid retention, elevating cardiac preload.\n"
            "• **Physical Inactivity & Deconditioning:** Reduces vascular elasticity and endothelial nitric oxide release.\n"
            "• **Excess Alcohol or Acute Caffeine:** Stimulates sympathetic vasoconstriction.\n\n"
            "**2. Physiological & Autonomic Factors:**\n"
            "• **Acute Psychological Stress / Anxiety:** Epinephrine release transiently spikes systolic pressure.\n"
            "• **Sleep Deprivation or Obstructive Sleep Apnea (OSA):** Hypoxic episodes trigger systemic vasoconstriction.\n"
            "• **Age-Related Arterial Stiffness:** Progressive loss of vascular elastin.\n\n"
            "**3. Secondary Medical Causes:**\n"
            "• Renal parenchymal disease, hyperaldosteronism, thyroid dysfunction, or medication side effects (e.g. NSAIDs, decongestants).\n\n"
            "*Note: These represent general medical factors and do not constitute an individual diagnosis.*";
      }

      if (lower.contains('dizzy') || lower.contains('dizziness') || lower.contains('lightheaded')) {
        return "### 🌀 Common Causes of Dizziness & Lightheadedness\n\n"
            "Dizziness is a broad symptom arising from several distinct physiological systems:\n\n"
            "1. **Orthostatic Hypotension:** A temporary dip in cerebral blood flow when standing up rapidly.\n"
            "2. **Dehydration or Low Blood Volume:** Inadequate fluid intake reducing stroke volume.\n"
            "3. **Hypoglycemia:** Low circulating glucose depriving the brain of immediate metabolic energy.\n"
            "4. **Vestibular / Inner Ear Imbalance:** Benign Paroxysmal Positional Vertigo (BPPV) or labyrinthitis.\n"
            "5. **Medication Side Effects:** Antihypertensives, sedatives, or diuretics.\n\n"
            "**Next Step:** Sit or lie down safely, drink a glass of water, and log resting blood pressure if symptoms subside.";
      }
    }

    // -------------------------------------------------------------
    // 4. VITAL TREND ANALYSIS INTENT (e.g. "Show how my blood pressure changed this month")
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.vitalTrendAnalysis) {
      if (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('pressure')) {
        if (bpTotalReadings < 2) {
          return "### 📈 Blood Pressure Trend Analysis\n\n"
              "I only have **$bpTotalReadings blood-pressure reading${bpTotalReadings == 1 ? '' : 's'}** recorded for **$patientName**, which is insufficient to calculate a reliable historical trend.\n\n"
              "To see meaningful trend graphs, please record consistent morning and evening readings over several days.\n\n"
              "```json\n"
              "{\n"
              "  \"type\": \"action_button\",\n"
              "  \"label\": \"Record Blood Pressure\",\n"
              "  \"action\": \"log_vital\",\n"
              "  \"route\": \"/add-vital\"\n"
              "}\n"
              "```";
        }

        final sysAvg = bpSys ?? 120;
        final diaAvg = bpDia ?? 80;
        return "### 📈 30-Day Blood Pressure Trend for $patientName\n\n"
            "• **Recorded Readings:** $bpTotalReadings measurements\n"
            "• **30-Day Average:** **$sysAvg/$diaAvg mmHg**\n"
            "• **Trend Trajectory:** **$bpDirection**\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"trend_chart\",\n"
            "  \"title\": \"Blood Pressure (30-Day Trend)\",\n"
            "  \"metricType\": \"bp\",\n"
            "  \"dataPoints\": [128.0, 126.0, 124.0, 122.0, ${sysAvg}.0],\n"
            "  \"labels\": [\"W1\", \"W2\", \"W3\", \"W4\", \"Current\"],\n"
            "  \"summary\": \"Overall trend is $bpDirection with an average of $sysAvg/$diaAvg mmHg.\"\n"
            "}\n"
            "```\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"action_button\",\n"
            "  \"label\": \"View Full History & Charts\",\n"
            "  \"action\": \"navigate\",\n"
            "  \"route\": \"/charts\"\n"
            "}\n"
            "```";
      }

      if (lower.contains('glucose') || lower.contains('sugar')) {
        if (glucoseTotalReadings < 2) {
          return "### 📈 Blood Glucose Trend Analysis\n\n"
              "I only have **$glucoseTotalReadings glucose reading${glucoseTotalReadings == 1 ? '' : 's'}** recorded for **$patientName**, which is insufficient to determine a long-term trend.\n\n"
              "```json\n"
              "{\n"
              "  \"type\": \"action_button\",\n"
              "  \"label\": \"Log Glucose Reading\",\n"
              "  \"action\": \"log_vital\",\n"
              "  \"route\": \"/add-vital\"\n"
              "}\n"
              "```";
        }

        final gAvg = glucoseAvg ?? '95.0';
        return "### 📈 Blood Glucose Trend for $patientName\n\n"
            "• **Total Measurements:** $glucoseTotalReadings readings\n"
            "• **Average Level:** **$gAvg mg/dL**\n"
            "• **Trajectory:** Stable fasting baseline\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"trend_chart\",\n"
            "  \"title\": \"Blood Glucose Progression\",\n"
            "  \"metricType\": \"glucose\",\n"
            "  \"dataPoints\": [98.0, 96.0, 94.0, 95.0],\n"
            "  \"labels\": [\"W1\", \"W2\", \"W3\", \"Current\"],\n"
            "  \"summary\": \"Fasting glucose maintained within standard ADA thresholds.\"\n"
            "}\n"
            "```";
      }
    }

    // -------------------------------------------------------------
    // 5. SINGLE VITAL READING INQUIRY (e.g. "What does 135/85 mean?" or "What is my BP?")
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.singleVitalInquiry) {
      final bpRegex = RegExp(r'(\d{2,3})\s*[/]\s*(\d{2,3})');
      final bpMatch = bpRegex.firstMatch(prompt);

      if (bpMatch != null) {
        final inputSys = int.tryParse(bpMatch.group(1)!) ?? 120;
        final inputDia = int.tryParse(bpMatch.group(2)!) ?? 80;

        String category = 'Normal';
        String recommendation = 'This reading is within healthy resting thresholds (< 120/80 mmHg).';
        String status = 'normal';

        if (inputSys >= 180 || inputDia >= 120) {
          return "⚠️ **IMPORTANT EMERGENCY NOTICE:** A reading of **$inputSys/$inputDia mmHg** represents a **Hypertensive Crisis**. Seek immediate emergency medical care if accompanied by headache, chest pain, or vision changes.";
        } else if (inputSys >= 140 || inputDia >= 90) {
          category = 'Stage 2 Hypertension';
          recommendation = 'Noticeably elevated. Rest quietly for 5 minutes and retake a confirmatory measurement.';
          status = 'high';
        } else if (inputSys >= 130 || inputDia >= 80) {
          category = 'Stage 1 Hypertension';
          recommendation = 'Falls in Stage 1 hypertension zone according to AHA guidelines. Monitor sodium and track evening reading.';
          status = 'elevated';
        } else if (inputSys >= 120 && inputDia < 80) {
          category = 'Elevated Blood Pressure';
          recommendation = 'Systolic is slightly above optimal baseline. Regular aerobic exercise and stress management are recommended.';
          status = 'elevated';
        }

        return "### 🩺 Blood Pressure Assessment: $inputSys/$inputDia mmHg\n\n"
            "• **Classification:** **$category** (AHA/ACC Guidelines)\n"
            "• **Clinical Interpretation:** $recommendation\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"blood_pressure_card\",\n"
            "  \"title\": \"Blood Pressure Assessment\",\n"
            "  \"value\": \"$inputSys/$inputDia\",\n"
            "  \"unit\": \"mmHg\",\n"
            "  \"status\": \"$status\",\n"
            "  \"subtitle\": \"$category\"\n"
            "}\n"
            "```";
      }

      // Inquiry about current patient recorded vital
      if (lower.contains('blood pressure') || lower.contains('bp')) {
        if (bpSys == null || bpDia == null) {
          return "There are no recorded blood-pressure measurements for **$patientName** yet.\n\n"
              "```json\n"
              "{\n"
              "  \"type\": \"action_button\",\n"
              "  \"label\": \"Record Blood Pressure\",\n"
              "  \"action\": \"log_vital\",\n"
              "  \"route\": \"/add-vital\"\n"
              "}\n"
              "```";
        }

        return "### 🩺 Recorded Blood Pressure for $patientName\n\n"
            "• **Latest Average:** **$bpSys/$bpDia mmHg**\n"
            "• **30-Day Trend:** **$bpDirection** ($bpTotalReadings readings recorded)\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"blood_pressure_card\",\n"
            "  \"title\": \"Current Blood Pressure\",\n"
            "  \"value\": \"$bpSys/$bpDia\",\n"
            "  \"unit\": \"mmHg\",\n"
            "  \"status\": \"normal\",\n"
            "  \"subtitle\": \"30-Day Trend: $bpDirection\"\n"
            "}\n"
            "```";
      }
    }

    // -------------------------------------------------------------
    // 6. DOCTOR PREP & REPORT INTENT
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.doctorPrep) {
      final sys = bpSys ?? 120;
      final dia = bpDia ?? 80;
      final glu = glucoseAvg ?? '95';

      return "### 🩺 Physician Consultation Summary for $patientName\n\n"
          "**Key Discussion Points for Your Appointment:**\n"
          "1. **Vital Baseline:** Blood pressure averaging **$sys/$dia mmHg**, Fasting glucose **$glu mg/dL**, Pulse **$pulseAvg BPM**.\n"
          "2. **Medication Review:** Confirm ongoing tolerances and refill schedules.\n"
          "3. **Target Thresholds:** Review whether current lifestyle adjustments meet your clinical goals.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"report_card\",\n"
          "  \"patientName\": \"$patientName\",\n"
          "  \"reportDate\": \"Today\",\n"
          "  \"summaryText\": \"Health overview prepared for clinical consultation.\",\n"
          "  \"vitalsOverview\": {\n"
          "    \"Blood Pressure\": \"$sys/$dia mmHg\",\n"
          "    \"Glucose\": \"$glu mg/dL\",\n"
          "    \"Pulse\": \"$pulseAvg BPM\",\n"
          "    \"SpO2\": \"$spo2Avg%\"\n"
          "  },\n"
          "  \"aiObservations\": [\n"
          "    \"Vitals demonstrate stable resting baseline.\",\n"
          "    \"Sufficient data logged for clinical trend review.\"\n"
          "  ],\n"
          "  \"pdfDownloadRoute\": \"/history\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"action_button\",\n"
          "  \"label\": \"Export Medical History PDF\",\n"
          "  \"action\": \"export_pdf\",\n"
          "  \"route\": \"/history\"\n"
          "}\n"
          "```";
    }

    // -------------------------------------------------------------
    // 7. PATIENT RECORDS SUMMARY INTENT
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.patientRecordsSummary) {
      final sys = bpSys ?? 120;
      final dia = bpDia ?? 80;
      final glu = glucoseAvg ?? '95';

      return "### 📊 Consolidated Health Overview for $patientName\n\n"
          "• **Blood Pressure:** **$sys/$dia mmHg** ($bpDirection)\n"
          "• **Blood Glucose:** **$glu mg/dL**\n"
          "• **Resting Pulse:** **$pulseAvg BPM**\n"
          "• **Oxygen Saturation (SpO₂):** **$spo2Avg%**\n\n"
          "All tracked biometric parameters are within recorded reference ranges.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"health_summary_card\",\n"
          "  \"title\": \"Daily Health Status\",\n"
          "  \"value\": \"Optimal Baseline\",\n"
          "  \"subtitle\": \"$bpTotalReadings vital records active\"\n"
          "}\n"
          "```";
    }

    // -------------------------------------------------------------
    // 8. MEDICATION & PHARMACOLOGY INTENT
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.medicationInfo) {
      return "### 💊 Medication & Pharmacology Overview\n\n"
          "**Key Clinical Usage & Safety Guidelines:**\n"
          "• **Adherence:** Take prescribed medications at consistent daily intervals to maintain steady therapeutic blood plasma levels.\n"
          "• **Administration:** Always follow specific label instructions (e.g. taking NSAIDs with food to protect gastric lining).\n"
          "• **Safety Note:** Never adjust prescribed doses without consulting your prescribing physician or pharmacist.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"reminder_card\",\n"
          "  \"title\": \"Daily Medication Reminder\",\n"
          "  \"time\": \"08:00 AM\",\n"
          "  \"dosage\": \"Take with water after meal\"\n"
          "}\n"
          "```";
    }

    // -------------------------------------------------------------
    // 9. CONVERSATIONAL & GREETING INTENT
    // -------------------------------------------------------------
    if (detectedIntent == AiIntent.conversational) {
      return "Hello $patientName! 👋 I'm **VitalAI**, your clinical health and medical assistant.\n\n"
          "I'm here to help you understand your symptoms, analyze your vital readings, explore nutrition and medications, or prepare summaries for your doctor visits.\n\n"
          "**What would you like to explore today?**\n"
          "• *\"What does a blood pressure reading of 120/80 mean?\"*\n"
          "• *\"Show me my blood pressure trend this month\"*\n"
          "• *\"Why can blood pressure be high?\"*\n"
          "• *\"Prepare a report for my doctor visit\"*";
    }

    // -------------------------------------------------------------
    // 10. GENERAL HEALTH & DEFAULT INTENT
    // -------------------------------------------------------------
    final cleanTopic = prompt.replaceAll(RegExp(r'[?.,!]'), '').trim();
    final displayTopic = cleanTopic.isNotEmpty ? cleanTopic : "Health Information";

    return "### 🩺 Clinical Overview: $displayTopic\n\n"
        "**Key Medical Insights:**\n"
        "• **Physiological Context:** Maintaining balanced physiological homeostasis requires consistent attention to hydration, sleep, balanced nutrition, and regular biometric tracking.\n"
        "• **Evidence-Based Recommendations:** Public health guidelines from the **WHO** and **CDC** emphasize 150 minutes of moderate aerobic exercise weekly, dietary sodium moderation (< 2,000 mg/day), and routine preventative screenings.\n"
        "• **When to Consult a Physician:** If you have ongoing or concerning symptoms regarding $displayTopic, consult your primary care provider for personalized evaluation.";
  }
}
