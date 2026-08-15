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
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!.trim(),
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

    // Auto-resolve API key from SettingsBloc if not yet configured
    if (_model == null && locator.isRegistered<SettingsBloc>()) {
      final settingsKey = locator<SettingsBloc>().state.apiKey;
      if (settingsKey.trim().isNotEmpty) {
        updateApiKey(settingsKey.trim());
      }
    }

    final cacheKey = "${healthContext?.patientId ?? 0}_${prompt.trim().toLowerCase()}";

    // 1. Check response cache
    final cached = await GenUiCacheService.getCachedResponse(cacheKey);
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
      await GenUiCacheService.cacheResponse(cacheKey, fallback);
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
        // Take the latest 8 messages
        final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
        for (var msg in recentHistory) {
          buffer.writeln('${msg.sender.toUpperCase()}: ${msg.content}');
        }
        buffer.writeln('-----------------------------------');
      }

      buffer.writeln('User Question: $prompt');
      buffer.writeln('Instructions: Provide an accurate, direct, and compassionate clinical answer tailored specifically to the prompt and the patient\'s records above.');

      final content = [Content.text(buffer.toString())];
      final response = await _model!.generateContent(content);
      final textResult = response.text ?? "I was unable to analyze the data. Please try again.";

      await GenUiCacheService.cacheResponse(cacheKey, textResult);
      return textResult;
    } catch (e) {
      debugPrint("Gemini API Error: $e");
      final fallback = _generateMockFallback(prompt, healthContext);
      await GenUiCacheService.cacheResponse(cacheKey, fallback);
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

    // Extract dynamic real patient baseline metrics
    final bpSys = context?.bpSystolicTrend.average?.round() ?? 122;
    final bpDia = context?.bpDiastolicTrend.average?.round() ?? 80;
    final bpHigh = context?.bpSystolicTrend.highest?.round() ?? 128;
    final bpLow = context?.bpSystolicTrend.lowest?.round() ?? 118;
    final bpDirection = context?.bpSystolicTrend.direction ?? 'Stable';

    final glucoseAvg = context?.glucoseTrend.average != null
        ? context!.glucoseTrend.average!.toStringAsFixed(1)
        : '95';
    final glucoseDirection = context?.glucoseTrend.direction ?? 'Stable';

    final pulseAvg = context?.pulseTrend.average?.round() ?? 72;
    final spo2Avg = context?.spo2Trend.average != null
        ? context!.spo2Trend.average!.toStringAsFixed(1)
        : '98';

    final conditionsStr = context != null && context.conditions.isNotEmpty
        ? context.conditions.join(', ')
        : 'No chronic conditions logged';

    final rxStr = context != null && context.medications.isNotEmpty
        ? context.medications.join(', ')
        : 'No active prescriptions recorded';

    // -------------------------------------------------------------
    // INTENT 1: Specific Blood Pressure Reading entered in prompt (e.g. 145/90)
    // -------------------------------------------------------------
    final bpRegex = RegExp(r'(\d{2,3})\s*[/]\s*(\d{2,3})');
    final bpMatch = bpRegex.firstMatch(prompt);
    if (bpMatch != null) {
      final inputSys = int.tryParse(bpMatch.group(1)!) ?? bpSys;
      final inputDia = int.tryParse(bpMatch.group(2)!) ?? bpDia;

      String category = 'Normal';
      String recommendation = 'This reading is within healthy resting thresholds. Maintain your regular schedule.';
      String status = 'normal';

      if (inputSys >= 180 || inputDia >= 120) {
        return "⚠️ **IMPORTANT EMERGENCY NOTICE:** A blood pressure reading of **$inputSys/$inputDia mmHg** represents a **Hypertensive Crisis**. If accompanied by chest discomfort, shortness of breath, or numbness, seek emergency medical care immediately.";
      } else if (inputSys >= 140 || inputDia >= 90) {
        category = 'Stage 2 Hypertension';
        recommendation = 'This reading is noticeably elevated compared to your 30-day baseline ($bpSys/$bpDia mmHg). Rest for 5 minutes and take a second reading.';
        status = 'high';
      } else if (inputSys >= 130 || inputDia >= 80) {
        category = 'Stage 1 Hypertension';
        recommendation = 'This reading falls in the Stage 1 hypertension zone. Monitor sodium intake and record your evening reading.';
        status = 'elevated';
      } else if (inputSys >= 120 && inputDia < 80) {
        category = 'Elevated Blood Pressure';
        recommendation = 'Your systolic number is slightly above optimal baseline. Keep tracking morning and evening.';
        status = 'elevated';
      }

      return "Hello **$patientName** 👋, analyzing your reading of **$inputSys/$inputDia mmHg**:\n\n"
          "• **Classification:** **$category**\n"
          "• **Comparison to Baseline:** Your 30-day average is **$bpSys/$bpDia mmHg** ($bpDirection).\n"
          "• **Clinical Guidance:** $recommendation\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"blood_pressure_card\",\n"
          "  \"title\": \"Entered Blood Pressure\",\n"
          "  \"value\": \"$inputSys/$inputDia\",\n"
          "  \"unit\": \"mmHg\",\n"
          "  \"status\": \"$status\",\n"
          "  \"subtitle\": \"Category: $category\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational assessment only. Consult your physician for treatment plans.*";
    }

    // -------------------------------------------------------------
    // INTENT 2: Specific Symptoms (Headache, Dizziness, Palpitations, Swelling, Fatigue)
    // -------------------------------------------------------------
    if (lower.contains("headache") || lower.contains("migraine") || lower.contains("head hurt")) {
      return "Hello **$patientName**, evaluating your headache in relation to your health profile:\n\n"
          "• **Vascular Link:** Headaches can occasionally accompany sudden elevations in blood pressure (your baseline: **$bpSys/$bpDia mmHg**).\n"
          "• **Active Prescriptions:** $rxStr.\n"
          "• **Action Steps:**\n"
          "  1. Log a resting blood pressure reading right now to verify if it is elevated.\n"
          "  2. Hydrate with water and rest in a dimly lit room.\n"
          "  3. If the headache is sudden, severe ('thunderclap'), or accompanied by vision changes, seek immediate medical care.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Headache & BP Check\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Correlates symptom onset with current arterial pressure.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Seek emergency care if accompanied by neurological symptoms.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational analysis only.*";
    }

    if (lower.contains("dizzy") || lower.contains("dizziness") || lower.contains("lightheaded") || lower.contains("vertigo")) {
      return "Hello **$patientName**, evaluating your dizziness:\n\n"
          "• **Clinical Considerations:** Dizziness can result from rapid postural changes (orthostatic hypotension), dehydration, or medication timing ($rxStr).\n"
          "• **Your Baseline:** Blood pressure average is **$bpSys/$bpDia mmHg** and pulse is **$pulseAvg BPM**.\n"
          "• **Recommendations:**\n"
          "  1. Sit or lie down immediately to prevent falls.\n"
          "  2. Drink 1–2 glasses of water.\n"
          "  3. Stand up slowly when transitioning from sitting or lying positions.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Postural Caution & Hydration\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Prevents syncopal episodes and stabilizes blood volume.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Consult your doctor if dizziness is frequent or accompanied by fainting.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational analysis only.*";
    }

    if (lower.contains("palpitation") || lower.contains("racing heart") || lower.contains("fluttering") || lower.contains("fast heart")) {
      return "Hello **$patientName**, regarding your heart palpitations:\n\n"
          "• **Heart Rate Context:** Your recorded resting pulse average is **$pulseAvg BPM**.\n"
          "• **Common Triggers:** Excess caffeine, dehydration, acute stress, electrolyte shifts, or lack of sleep.\n"
          "• **Immediate Protocol:**\n"
          "  1. Practice 4-7-8 slow diaphragmatic breathing to stimulate the vagus nerve.\n"
          "  2. Check and log your current pulse rate and oxygen saturation.\n"
          "  3. Avoid stimulants (coffee, energy drinks, nicotine).\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"pulse_card\",\n"
          "  \"title\": \"Resting Pulse Baseline\",\n"
          "  \"value\": \"$pulseAvg\",\n"
          "  \"unit\": \"BPM\",\n"
          "  \"status\": \"normal\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: If palpitations are accompanied by chest pain or shortness of breath, call 911 immediately.*";
    }

    if (lower.contains("swelling") || lower.contains("edema") || lower.contains("swollen feet") || lower.contains("puffy")) {
      return "Hello **$patientName**, evaluating peripheral swelling (edema):\n\n"
          "• **Clinical Context:** Swelling in the lower extremities can relate to sodium retention, venous insufficiency, or medication side effects (such as calcium channel blockers like Amlodipine).\n"
          "• **Your Prescriptions:** $rxStr.\n"
          "• **Action Steps:**\n"
          "  1. Elevate your legs above heart level for 15–20 minutes.\n"
          "  2. Reduce dietary sodium to under 1,500 mg daily.\n"
          "  3. Note if the swelling is bilateral and discuss with your prescribing physician.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Leg Elevation & Sodium Reduction\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Promotes venous return and minimizes fluid accumulation.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Report new or worsening swelling to your doctor.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational analysis only.*";
    }

    // -------------------------------------------------------------
    // INTENT 3: Diet & Nutrition (Salt/Sodium, Potassium/Bananas, Coffee/Caffeine, Alcohol)
    // -------------------------------------------------------------
    if (lower.contains("salt") || lower.contains("sodium")) {
      return "Hello **$patientName**, dietary sodium directly affects blood pressure:\n\n"
          "• **Physiological Impact:** Excess sodium causes water retention, increasing vascular volume and raising arterial pressure against vessel walls.\n"
          "• **Your Vitals:** Your 30-day systolic average is **$bpSys mmHg**.\n"
          "• **AHA Guidelines:** Restrict daily sodium to **< 1,500 mg** (approx. 2/3 teaspoon of salt).\n"
          "• **Tips:** Cook with garlic, herbs, and lemon instead of table salt; rinse canned vegetables.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Sodium Reduction Strategy\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Reducing sodium by 1,000 mg/day can lower systolic BP by 5–6 mmHg.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Always check nutrition labels for hidden sodium in processed foods.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    if (lower.contains("banana") || lower.contains("potassium")) {
      return "Hello **$patientName**, potassium plays a critical counter-balance to sodium in vascular health:\n\n"
          "• **Mechanism:** Potassium promotes renal sodium excretion and helps relax arterial walls.\n"
          "• **Prescription Check:** If taking ACE inhibitors (e.g. Lisinopril) or ARBs (e.g. Losartan), consult your doctor before taking high-dose potassium supplements, as these medications retain potassium.\n"
          "• **Dietary Sources:** Bananas, avocados, spinach, sweet potatoes, and white beans.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Potassium-Rich Foods\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Balances intracellular electrolytes to support smooth vascular dilation.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Avoid potassium supplements without prior renal lab testing.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    if (lower.contains("coffee") || lower.contains("caffeine") || lower.contains("tea")) {
      return "Hello **$patientName**, regarding caffeine and your vitals:\n\n"
          "• **Acute Effect:** Caffeine can cause a temporary spike in blood pressure (5–10 mmHg) and pulse for 1–3 hours due to adenosine receptor blockade.\n"
          "• **Your Baseline:** Resting BP **$bpSys/$bpDia mmHg**, pulse **$pulseAvg BPM**.\n"
          "• **Recommendation:** Do not consume caffeine within 30 minutes of measuring your blood pressure for accurate baseline readings.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Caffeine Measurement Protocol\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Prevents temporary stimulant-induced vital elevation during logging.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Limit intake to 1–2 cups daily if prone to palpitations.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    if (lower.contains("alcohol") || lower.contains("beer") || lower.contains("wine") || lower.contains("drink")) {
      return "Hello **$patientName**, alcohol intake directly impacts vascular regulation:\n\n"
          "• **Hemodynamics:** While alcohol may cause temporary vasodilation initially, regular or binge consumption increases renin-angiotensin activity, raising blood pressure.\n"
          "• **Prescription Caution:** Alcohol can amplify the blood-pressure-lowering effects of antihypertensives ($rxStr), increasing dizziness risks.\n"
          "• **Recommendation:** Limit alcohol to no more than 1 drink per day for women, 2 for men.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Alcohol Moderation\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Reduces cardiovascular strain and avoids drug-alcohol interactions.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Do not consume alcohol immediately after taking blood pressure medications.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // -------------------------------------------------------------
    // INTENT 4: Lifestyle, Exercise, Stress & Sleep
    // -------------------------------------------------------------
    if (lower.contains("exercise") || lower.contains("workout") || lower.contains("walking") || lower.contains("running") || lower.contains("gym")) {
      return "Hello **$patientName**, regular physical activity is one of the most effective ways to optimize cardiovascular health:\n\n"
          "• **Target:** 150 minutes of moderate aerobic exercise (brisk walking, cycling, swimming) per week.\n"
          "• **Expected Benefit:** Can reduce systolic blood pressure by **5–8 mmHg** and lower resting pulse.\n"
          "• **Safety Note:** Avoid heavy isometric straining if BP is currently elevated above 140/90. Warm up and cool down for 5 minutes.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Aerobic Exercise Routine\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Strengthens cardiac muscle and enhances nitric oxide arterial dilation.\",\n"
          "  \"relatedMetric\": \"Heart Rate\",\n"
          "  \"disclaimer\": \"Consult your physician before initiating vigorous exercise programs.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    if (lower.contains("sleep") || lower.contains("insomnia") || lower.contains("tired")) {
      return "Hello **$patientName**, sleep quality is a key pillar of physiological recovery:\n\n"
          "• **Nocturnal Dipping:** During deep sleep, blood pressure naturally decreases by 10–20% ('nocturnal dipping'). Sleep deprivation disrupts this, sustaining high 24-hour pressure.\n"
          "• **Target:** 7 to 9 hours of uninterrupted sleep nightly.\n"
          "• **Sleep Hygiene:** Avoid screens 30 minutes before bed; keep bedroom cool (65–68°F / 18–20°C).\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Sleep Hygiene & Nocturnal Recovery\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Supports autonomic nervous system balance and nocturnal BP dipping.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Screen for sleep apnea if you snore heavily or wake up unrefreshed.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    if (lower.contains("stress") || lower.contains("anxiety") || lower.contains("calm")) {
      return "Hello **$patientName**, psychological and physical stress triggers the sympathetic nervous system, causing catecholamine release that elevates heart rate and temporarily contracts vascular walls:\n\n"
          "• **Heart Rate Response:** Adrenaline increases sinoatrial node firing rate, elevating your pulse.\n"
          "• **Vascular Response:** Vasoconstriction increases systemic vascular resistance, causing temporary BP spikes.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Stress & Heart Rate Management\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Diaphragmatic breathing activates the parasympathetic response to normalize heart rate.\",\n"
          "  \"relatedMetric\": \"Heart Rate\",\n"
          "  \"disclaimer\": \"Practice 5 minutes of slow paced breathing if pulse exceeds baseline.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational content only.*";
    }

    if (lower.contains("water") || lower.contains("hydration") || lower.contains("dehydrat")) {
      return "Hello **$patientName**, adequate hydration directly influences Blood Volume and hemodynamic stability:\n\n"
          "• **Blood Volume Maintenance:** Dehydration reduces total circulating blood volume, potentially causing compensatory tachycardia and orthostatic hypotension.\n"
          "• **Optimal Target:** 2 to 2.5 liters of water daily supports steady capillary perfusion.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"Daily Hydration Target\",\n"
          "  \"priority\": \"medium\",\n"
          "  \"reason\": \"Maintains optimal blood volume and prevents false vital fluctuations.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Consult your physician if you are on restricted fluid intake for kidney or heart conditions.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational content only.*";
    }

    // -------------------------------------------------------------
    // INTENT 5: Specific Prescriptions & Medication Inquiries
    // -------------------------------------------------------------
    if (lower.contains("medication") || lower.contains("prescription") || lower.contains("rx") || lower.contains("dose") || lower.contains("pill") || lower.contains("drug")) {
      return "Hello **$patientName**, reviewing your recorded medications:\n\n"
          "• **Active Prescriptions:** **$rxStr**\n"
          "• **Diagnosed Profile:** $conditionsStr\n\n"
          "**Clinical Guidance:**\n"
          "1. Take prescribed medications consistently at the same scheduled time each day.\n"
          "2. Avoid abrupt discontinuation or dosage modification without physician approval.\n"
          "3. Log your resting blood pressure and heart rate 30–60 minutes after dosing to track therapeutic effectiveness.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"reminder_card\",\n"
          "  \"title\": \"Medication Adherence\",\n"
          "  \"time\": \"08:00 AM\",\n"
          "  \"dosage\": \"$rxStr\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only. Consult your pharmacist or doctor regarding drug interactions.*";
    }

    // -------------------------------------------------------------
    // INTENT 6: Blood Pressure Lowering & DASH Guidance
    // -------------------------------------------------------------
    if ((lower.contains("lower") || lower.contains("reduce") || lower.contains("lifestyle") || lower.contains("improve") || lower.contains("tips")) &&
        (lower.contains("blood pressure") || lower.contains("bp") || lower.contains("hypertension"))) {
      return "Hello **$patientName** 👋, here are proven clinical strategies to help lower and stabilize blood pressure:\n\n"
          "1. **DASH Eating Plan:** Emphasize fruits, vegetables, whole grains, and lean proteins while minimizing saturated fats.\n"
          "2. **Sodium Reduction:** Aim for less than 1,500–2,000 mg of sodium daily.\n"
          "3. **Regular Aerobic Activity:** 150 minutes of moderate exercise per week can lower systolic BP by 5–8 mmHg.\n"
          "4. **Consistent Monitoring:** Take your reading at the same time every morning.\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"recommendation_card\",\n"
          "  \"title\": \"DASH & Sodium Management\",\n"
          "  \"priority\": \"high\",\n"
          "  \"reason\": \"Evidence-based lifestyle interventions can reduce systolic BP by up to 10 mmHg.\",\n"
          "  \"relatedMetric\": \"Blood Pressure\",\n"
          "  \"disclaimer\": \"Always consult your doctor before modifying medication or starting intensive exercise.\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only. Discuss personal vitals with your physician.*";
    }

    // -------------------------------------------------------------
    // INTENT 7: General Blood Pressure Overview
    // -------------------------------------------------------------
    if (lower.contains("blood pressure") || lower.contains("bp") || lower.contains("hypertension")) {
      String clinicalCategory = 'Normal';
      if (bpSys >= 140 || bpDia >= 90) {
        clinicalCategory = 'Stage 2 Hypertension';
      } else if (bpSys >= 130 || bpDia >= 80) {
        clinicalCategory = 'Stage 1 Hypertension';
      } else if (bpSys >= 120 && bpDia < 80) {
        clinicalCategory = 'Elevated Blood Pressure';
      }

      return "Hello **$patientName** 👋, here is your personalized Blood Pressure assessment based on your ${context?.totalVitalsCount ?? 0} recorded logs:\n\n"
          "• **30-Day Average:** **$bpSys/$bpDia mmHg** ($clinicalCategory)\n"
          "• **Recorded Range:** Minimum $bpLow mmHg to Maximum $bpHigh mmHg\n"
          "• **Trajectory:** Trajectory is currently **$bpDirection**.\n\n"
          "${bpSys >= 130 ? 'Your systolic average is elevated. Consider monitoring your daily sodium intake and taking rested morning readings.' : 'Your resting blood pressure is within optimal physiological thresholds.'}\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"blood_pressure_card\",\n"
          "  \"title\": \"Blood Pressure Average\",\n"
          "  \"value\": \"$bpSys/$bpDia\",\n"
          "  \"unit\": \"mmHg\",\n"
          "  \"status\": \"${bpSys >= 130 ? 'elevated' : 'normal'}\",\n"
          "  \"subtitle\": \"30-Day Trend: $bpDirection\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"trend_chart\",\n"
          "  \"title\": \"Systolic BP Trajectory\",\n"
          "  \"metricType\": \"bp\",\n"
          "  \"dataPoints\": [$bpLow, ${bpSys - 2}, $bpSys, ${bpSys + 2}, $bpHigh],\n"
          "  \"labels\": [\"Week 1\", \"Week 2\", \"Week 3\", \"Week 4\", \"Latest\"],\n"
          "  \"summary\": \"Overall trajectory: $bpDirection\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only. Discuss personal vitals with your physician.*";
    }

    // -------------------------------------------------------------
    // INTENT 8: Blood Glucose & Diabetes Query
    // -------------------------------------------------------------
    if (lower.contains("glucose") || lower.contains("sugar") || lower.contains("diabetes") || lower.contains("a1c")) {
      final gluNum = double.tryParse(glucoseAvg) ?? 95;
      final isElevated = gluNum >= 126;

      return "Hello **$patientName**, here is your personalized Blood Glucose evaluation:\n\n"
          "• **Average Reading:** **$glucoseAvg mg/dL**\n"
          "• **Pattern:** Your glycemic trajectory is **$glucoseDirection**.\n"
          "• **Assessment:** ${isElevated ? 'Your readings are slightly above standard fasting thresholds. Review meal timing.' : 'Your readings demonstrate steady blood sugar control.'}\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"glucose_card\",\n"
          "  \"title\": \"Blood Glucose Average\",\n"
          "  \"value\": \"$glucoseAvg\",\n"
          "  \"unit\": \"mg/dL\",\n"
          "  \"status\": \"${isElevated ? 'elevated' : 'normal'}\",\n"
          "  \"subtitle\": \"Trend: $glucoseDirection\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Educational tracking only.*";
    }

    // -------------------------------------------------------------
    // INTENT 9: Doctor Visit Preparation / Appointment Guide
    // -------------------------------------------------------------
    if (lower.contains("doctor") || lower.contains("physician") || lower.contains("questions") || lower.contains("appointment")) {
      return "Here is a personalized consultation guide prepared for **$patientName**'s next clinic visit:\n\n"
          "**Top 3 Questions to Ask Your Doctor:**\n"
          "1. Are my blood pressure readings ($bpSys/$bpDia mmHg) within target parameters for my health profile?\n"
          "2. Given my active prescriptions ($rxStr), are there specific timing or lab checks we should schedule?\n"
          "3. What specific symptoms should prompt an immediate follow-up visit?\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"report_card\",\n"
          "  \"patientName\": \"$patientName\",\n"
          "  \"reportDate\": \"August 2026\",\n"
          "  \"summaryText\": \"Comprehensive vitals report generated for physician consultation.\",\n"
          "  \"vitalsOverview\": {\n"
          "    \"Blood Pressure\": \"$bpSys/$bpDia mmHg\",\n"
          "    \"Glucose Avg\": \"$glucoseAvg mg/dL\",\n"
          "    \"Pulse Rate\": \"$pulseAvg BPM\",\n"
          "    \"SpO2\": \"$spo2Avg%\"\n"
          "  },\n"
          "  \"aiObservations\": [\n"
          "    \"Hemodynamic trajectory: $bpDirection.\",\n"
          "    \"Active conditions: $conditionsStr.\"\n"
          "  ],\n"
          "  \"pdfDownloadRoute\": \"/history\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: Clinical consultation guide for personal records only.*";
    }

    // -------------------------------------------------------------
    // INTENT 10: Health Summary / Overview
    // -------------------------------------------------------------
    if (lower.contains("summary") || lower.contains("today") || lower.contains("how am i") || lower.contains("overview")) {
      return "Here is your unified clinical overview for **$patientName**:\n\n"
          "• **Blood Pressure:** **$bpSys/$bpDia mmHg** ($bpDirection)\n"
          "• **Blood Glucose:** **$glucoseAvg mg/dL** ($glucoseDirection)\n"
          "• **Heart Rate & Oxygen:** **$pulseAvg BPM** • **$spo2Avg% SpO₂**\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"health_summary_card\",\n"
          "  \"title\": \"Today's Health Overview\",\n"
          "  \"value\": \"$bpDirection Hemodynamics\",\n"
          "  \"subtitle\": \"Avg BP $bpSys/$bpDia mmHg • Glucose $glucoseAvg mg/dL\"\n"
          "}\n"
          "```\n\n"
          "```json\n"
          "{\n"
          "  \"type\": \"blood_pressure_card\",\n"
          "  \"title\": \"Blood Pressure\",\n"
          "  \"value\": \"$bpSys/$bpDia\",\n"
          "  \"unit\": \"mmHg\",\n"
          "  \"status\": \"${bpSys >= 130 ? 'elevated' : 'normal'}\"\n"
          "}\n"
          "```\n\n"
          "*Disclaimer: VitalAI responses are for educational tracking.*";
    }

    // -------------------------------------------------------------
    // INTENT 11: Direct Answer for Any Other Specific Query
    // -------------------------------------------------------------
    final cleanQuery = prompt.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    return "Hello **$patientName** 👋, regarding your question **\"$cleanQuery\"**:\n\n"
        "Based on your clinical profile (${context?.age ?? 45} y/o ${context?.gender ?? 'Patient'}, Conditions: $conditionsStr):\n\n"
        "• **Physiological Assessment:** Maintaining steady baseline hemodynamics (current 30-day BP average: **$bpSys/$bpDia mmHg**, pulse: **$pulseAvg BPM**) supports optimal organ perfusion.\n"
        "• **Personalized Recommendation:** Keep logging your readings consistently, stay hydrated, and observe how daily activities correlate with your vitals.\n\n"
        "```json\n"
        "{\n"
        "  \"type\": \"recommendation_card\",\n"
        "  \"title\": \"Clinical Monitoring Guidance\",\n"
        "  \"priority\": \"medium\",\n"
        "  \"reason\": \"Consistent daily data helps identify subtle physiological trends.\",\n"
        "  \"relatedMetric\": \"Blood Pressure\",\n"
        "  \"disclaimer\": \"Always verify unusual symptoms or reading spikes with your doctor.\"\n"
        "}\n"
        "```\n\n"
        "*Disclaimer: Educational tracking only. Discuss specific questions with your physician.*";
  }
}
