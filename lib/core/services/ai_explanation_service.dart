/// Service for generating clear, non-diagnostic, plain-language explanations
/// for common health vital metrics (SpO2, Blood Pressure, Glucose, BMI, Pulse).
class AiExplanationService {
  static const String disclaimer =
      "Note: This information is for educational purposes only and does not constitute medical diagnosis or advice. Always consult a qualified healthcare professional.";

  /// Returns educational explanation for vital metrics.
  static String explainMetric(String metricName) {
    switch (metricName.toLowerCase().replaceAll(' ', '_')) {
      case 'spo2':
      case 'oxygen_saturation':
        return "SpO₂ (Blood Oxygen Saturation) measures the percentage of oxygen carrying hemoglobin in your bloodstream. "
            "Normal resting readings generally range from 95% to 100%. If your readings consistently fall below this range, "
            "we recommend consulting a healthcare provider.\n\n$disclaimer";

      case 'blood_pressure':
      case 'bp':
        return "Blood pressure measures the force of your blood against artery walls. "
            "It consists of Systolic (top number, pressure during heartbeats) and Diastolic (bottom number, pressure at rest). "
            "A standard healthy resting reading is often near 120/80 mmHg. "
            "Persistent elevated readings should be reviewed with your doctor.\n\n$disclaimer";

      case 'glucose':
      case 'blood_sugar':
        return "Blood Glucose indicates the concentration of sugar present in your blood. "
            "Fasting glucose levels usually range between 70 and 99 mg/dL. "
            "Readings can naturally fluctuate after meals or exercise. For personalized targets, speak with your care provider.\n\n$disclaimer";

      case 'bmi':
      case 'body_mass_index':
        return "BMI (Body Mass Index) estimates body composition using your height and weight ratio. "
            "A healthy adult range typically spans 18.5 to 24.9. "
            "While useful as a general metric, it doesn't account for muscle mass or bone density. Consult a professional for comprehensive evaluation.\n\n$disclaimer";

      case 'pulse':
      case 'heart_rate':
        return "Pulse (Heart Rate) measures how many times your heart beats per minute (BPM). "
            "A typical resting heart rate for adults ranges from 60 to 100 BPM. "
            "Physical activity, stress, and caffeine can temporarily elevate your heart rate.\n\n$disclaimer";

      default:
        return "Regular tracking of your health vitals helps build a clearer picture of your overall wellness over time. "
            "Always consult your doctor for medical advice and interpretation of your readings.\n\n$disclaimer";
    }
  }

  /// Checks if a user prompt is specifically asking for a metric definition/explanation.
  static String? handleExplanationPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    
    // Do not intercept if user is asking for trend analysis or charts
    final isTrendOrChartQuery = lower.contains('trend') ||
        lower.contains('chart') ||
        lower.contains('graph') ||
        lower.contains('analyse') ||
        lower.contains('analyze') ||
        lower.contains('summary') ||
        lower.contains('overview') ||
        lower.contains('history') ||
        lower.contains('pattern');

    if (isTrendOrChartQuery) return null;

    // Only intercept if the user is asking what/explain/meaning/definition
    final isExplanationIntent = lower.contains('what is') ||
        lower.contains('what does') ||
        lower.contains('meaning') ||
        lower.contains('definition') ||
        lower.contains('what are');

    if (!isExplanationIntent) return null;

    if (lower.contains('spo2') || lower.contains('oxygen')) {
      return explainMetric('spo2');
    } else if (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('hypertension')) {
      return explainMetric('blood_pressure');
    } else if (lower.contains('glucose') || lower.contains('sugar') || lower.contains('diabetes')) {
      return explainMetric('glucose');
    } else if (lower.contains('bmi') || lower.contains('body mass')) {
      return explainMetric('bmi');
    } else if (lower.contains('pulse') || lower.contains('heart rate') || lower.contains('bpm')) {
      return explainMetric('pulse');
    }
    return null;
  }
}

