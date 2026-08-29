/// Clinical and conversational intent classification for user queries in VitalAI.
enum AiIntent {
  /// Simple definition, factual health query, or conceptual explanation (e.g., "What is blood pressure?", "What is BMI?")
  healthExplanation,

  /// Inquiring about possible physiological or lifestyle causes (e.g., "Why can blood pressure be high?", "What causes dizziness?")
  possibleCauses,

  /// Inquiring about a specific vital measurement or the user's latest reading (e.g., "What is my blood pressure?", "What does 135/85 mean?")
  singleVitalInquiry,

  /// Inquiring about vital progression or longitudinal trends (e.g., "Show me how my blood pressure has changed this month", "My glucose trend")
  vitalTrendAnalysis,

  /// Comparing historical periods or metrics (e.g., "Compare this week's BP to last week", "BP vs heart rate")
  vitalsComparison,

  /// Summarizing overall patient records / daily stats (e.g., "Show my health summary for today", "My vitals overview")
  patientRecordsSummary,

  /// Medication info, prescription timing, or pharmacological mechanism (e.g., "How does Metformin work?", "When should I take Lisinopril?")
  medicationInfo,

  /// Preparing for a clinical appointment or physician consultation (e.g., "Help me prepare for my doctor visit", "Doctor report summary")
  doctorPrep,

  /// Requesting a direct action or navigation (e.g., "Log my blood pressure reading", "Set a reminder", "View history")
  actionNavigation,

  /// General wellness, fitness, or nutrition query (e.g., "Suggest a heart-healthy meal", "What exercises are safe?")
  generalHealthFact,

  /// Acute, red-flag, or emergency symptom presentation (e.g., "Severe crushing chest pain", "Cannot breathe", "Sudden face drooping")
  safetyEmergency,

  /// Query cannot be answered reliably or data is insufficient
  insufficientData,

  /// General conversational / greeting
  conversational,
}

/// Lightweight, deterministic intent classifier assisting prompt tuning and conversational fallback.
class AiIntentClassifier {
  static AiIntent classify(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Emergency Safety Triggers
    if (lower.contains('chest pain') ||
        lower.contains('shortness of breath') ||
        lower.contains("can't breathe") ||
        lower.contains('cannot breathe') ||
        lower.contains('heart attack') ||
        lower.contains('stroke') ||
        lower.contains('facial droop') ||
        lower.contains('slurred speech') ||
        lower.contains('sudden numbness') ||
        lower.contains('emergency')) {
      return AiIntent.safetyEmergency;
    }

    // 2. Doctor Appointment Prep
    if (lower.contains('doctor') ||
        lower.contains('appointment') ||
        lower.contains('consultation') ||
        lower.contains('physician report') ||
        lower.contains('prep for doctor') ||
        lower.contains('clinic visit')) {
      return AiIntent.doctorPrep;
    }

    // 3. Comparison Queries
    if (lower.contains('compare') ||
        lower.contains('comparison') ||
        lower.contains('vs') ||
        lower.contains('this week vs last week') ||
        lower.contains('difference between my')) {
      return AiIntent.vitalsComparison;
    }

    // 4. Trend & History Analysis
    if (lower.contains('trend') ||
        lower.contains('changed this month') ||
        lower.contains('over time') ||
        lower.contains('progression') ||
        lower.contains('history of my') ||
        lower.contains('past month') ||
        lower.contains('last 30 days') ||
        lower.contains('chart my')) {
      return AiIntent.vitalTrendAnalysis;
    }

    // 5. Summary Overview
    if (lower.contains('summary') ||
        lower.contains("today's health") ||
        lower.contains('my vitals') ||
        lower.contains('my stats') ||
        lower.contains('overview') ||
        lower.contains('daily report')) {
      return AiIntent.patientRecordsSummary;
    }

    // 6. Direct Action & Navigation
    if (lower.startsWith('log ') ||
        lower.startsWith('record ') ||
        lower.startsWith('set reminder') ||
        lower.startsWith('add reminder') ||
        lower.startsWith('go to ') ||
        lower.startsWith('open ') ||
        lower.contains('take me to')) {
      return AiIntent.actionNavigation;
    }

    // 7. Medications & Pharmacology
    if (lower.contains('medication') ||
        lower.contains('prescription') ||
        lower.contains('pill') ||
        lower.contains('dosage') ||
        lower.contains('side effect') ||
        lower.contains('ibuprofen') ||
        lower.contains('paracetamol') ||
        lower.contains('tylenol') ||
        lower.contains('aspirin') ||
        lower.contains('metformin') ||
        lower.contains('lisinopril') ||
        lower.contains('atorvastatin') ||
        lower.contains('amlodipine') ||
        lower.contains('amoxicillin')) {
      return AiIntent.medicationInfo;
    }

    // 8. Possible Causes / Symptom inquiries
    if (lower.startsWith('why ') ||
        lower.contains('what causes') ||
        lower.contains('reasons for') ||
        lower.contains('why can') ||
        lower.contains('why is my') ||
        lower.contains('causes of') ||
        lower.contains('dizzy') ||
        lower.contains('dizziness') ||
        lower.contains('headache') ||
        lower.contains('fatigue') ||
        lower.contains('tired') ||
        lower.contains('nausea') ||
        lower.contains('palpitations')) {
      return AiIntent.possibleCauses;
    }

    // 9. Personal Vital Inquiry (e.g. "What is my blood pressure?", "What does my reading mean?", "135/85")
    final bpRegex = RegExp(r'(\d{2,3})\s*[/]\s*(\d{2,3})');
    final hasNumber = bpRegex.hasMatch(lower) || RegExp(r'\d+\s*(mg/dl|bpm|%|mmhg|kg|°c)').hasMatch(lower);
    if (hasNumber ||
        lower.contains('my reading') ||
        lower.contains('my blood pressure') ||
        lower.contains('my bp') ||
        lower.contains('my glucose') ||
        lower.contains('my sugar') ||
        lower.contains('my pulse') ||
        lower.contains('my heart rate') ||
        lower.contains('what is my') ||
        lower.contains('what does my blood pressure mean') ||
        lower.contains('is my bp') ||
        lower.contains('is my glucose') ||
        lower.contains('is my pulse') ||
        lower.contains('my latest')) {
      return AiIntent.singleVitalInquiry;
    }

    // 10. General Health / Definition Explanation (e.g. "What is blood pressure?", "What is BMI?")
    if (lower.startsWith('what is ') ||
        lower.startsWith('define ') ||
        lower.startsWith('explain ') ||
        lower.contains('what does bmi mean') ||
        lower.contains('what is normal blood pressure') ||
        lower.contains('normal range') ||
        lower.contains('reference range')) {
      return AiIntent.healthExplanation;
    }

    // 11. Nutrition & Wellness
    if (lower.contains('eat') ||
        lower.contains('diet') ||
        lower.contains('meal') ||
        lower.contains('food') ||
        lower.contains('breakfast') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('exercise') ||
        lower.contains('workout') ||
        lower.contains('walking') ||
        lower.contains('running') ||
        lower.contains('keto') ||
        lower.contains('fasting')) {
      return AiIntent.generalHealthFact;
    }

    // 12. Conversational
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.contains('who are you') ||
        lower.contains('what can you do') ||
        lower.contains('how are you')) {
      return AiIntent.conversational;
    }

    return AiIntent.generalHealthFact;
  }
}
