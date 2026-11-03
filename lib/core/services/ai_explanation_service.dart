/// Service for generating clear, authoritative, plain-language explanations
/// for common health vital metrics, lab tests, and clinical concepts.
class AiExplanationService {
  static const String disclaimer =
      "*Disclaimer: This information is for educational tracking and reference only and does not constitute medical diagnosis. Always consult a qualified healthcare professional for diagnosis or medical treatment.*";

  /// Returns educational explanation for vital metrics and health concepts.
  static String explainMetric(String metricName) {
    switch (metricName.toLowerCase().replaceAll(' ', '_')) {
      case 'spo2':
      case 'oxygen_saturation':
      case 'blood_oxygen':
        return "### 🫁 Blood Oxygen Saturation (SpO₂)\n\n"
            "• **What it is:** SpO₂ (Blood Oxygen Saturation) measures the percentage of oxygen-carrying hemoglobin in your red blood cells.\n"
            "• **Normal Range:** **95% to 100%** at sea level. Readings below 90% indicate hypoxemia.\n"
            "• **Key Factors:** Lung health, altitude, circulation, and breathing depth all influence SpO₂.\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Oxygen Saturation (SpO₂)\",\n"
            "  \"definition\": \"Percentage of oxygenated hemoglobin in arterial blood.\",\n"
            "  \"normalRange\": \"95% - 100%\",\n"
            "  \"illustrationIcon\": \"air_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'blood_pressure':
      case 'bp':
      case 'hypertension':
        return "### ❤️ Blood Pressure (BP)\n\n"
            "• **What it is:** The hydrostatic pressure exerted by circulating blood against the walls of blood vessels.\n"
            "• **Two Numbers:**\n"
            "  - **Systolic (Top):** Pressure when the ventricles contract and pump blood.\n"
            "  - **Diastolic (Bottom):** Resting pressure between heartbeats.\n"
            "• **Categories (AHA):**\n"
            "  - **Normal:** < 120 / < 80 mmHg\n"
            "  - **Elevated:** 120–129 / < 80 mmHg\n"
            "  - **Stage 1 Hypertension:** 130–139 / 80–89 mmHg\n"
            "  - **Stage 2 Hypertension:** ≥ 140 / ≥ 90 mmHg\n"
            "  - **Hypertensive Crisis:** > 180 and/or > 120 mmHg (Emergency)\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Blood Pressure Classification\",\n"
            "  \"definition\": \"Force exerted by circulating blood against arterial walls.\",\n"
            "  \"normalRange\": \"< 120/80 mmHg\",\n"
            "  \"illustrationIcon\": \"monitor_heart_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'glucose':
      case 'blood_sugar':
      case 'glycemia':
        return "### 🩸 Blood Glucose (Blood Sugar)\n\n"
            "• **What it is:** The concentration of glucose present in the bloodstream, providing primary cellular energy.\n"
            "• **Reference Ranges (Fasting):**\n"
            "  - **Normal:** 70 to 99 mg/dL (3.9 to 5.5 mmol/L)\n"
            "  - **Prediabetes:** 100 to 125 mg/dL\n"
            "  - **Diabetes:** ≥ 126 mg/dL on multiple tests\n"
            "• **Postprandial (2 hours after eating):** Typically under 140 mg/dL.\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Blood Glucose (Fasting)\",\n"
            "  \"definition\": \"Level of circulating sugar providing cellular fuel.\",\n"
            "  \"normalRange\": \"70 - 99 mg/dL\",\n"
            "  \"illustrationIcon\": \"bloodtype_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'cholesterol':
      case 'lipids':
      case 'ldl':
      case 'hdl':
        return "### 🧬 Cholesterol & Lipid Profile\n\n"
            "• **What it is:** A waxy, fat-like substance essential for building cell membranes, vitamin D, and hormones.\n"
            "• **Key Components:**\n"
            "  - **HDL (High-Density Lipoprotein - 'Good'):** Transports cholesterol from tissues to liver for elimination (Target: > 40 mg/dL men, > 50 mg/dL women).\n"
            "  - **LDL (Low-Density Lipoprotein - 'Bad'):** Can accumulate as plaque in arterial walls (Target: < 100 mg/dL).\n"
            "  - **Triglycerides:** Common type of stored body fat (Target: < 150 mg/dL).\n"
            "  - **Total Cholesterol:** Target: < 200 mg/dL.\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Lipid Profile (HDL vs LDL)\",\n"
            "  \"definition\": \"Circulating lipoproteins determining cardiovascular risk.\",\n"
            "  \"normalRange\": \"Total < 200 mg/dL, LDL < 100 mg/dL\",\n"
            "  \"illustrationIcon\": \"water_drop_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'a1c':
      case 'hba1c':
        return "### 📊 Hemoglobin A1C (HbA1c)\n\n"
            "• **What it is:** Measures the percentage of hemoglobin coated with sugar over the past 2–3 months.\n"
            "• **Ranges:**\n"
            "  - **Normal:** Below 5.7%\n"
            "  - **Prediabetes:** 5.7% to 6.4%\n"
            "  - **Diabetes:** 6.5% or higher\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Hemoglobin A1C\",\n"
            "  \"definition\": \"3-month average of blood sugar levels.\",\n"
            "  \"normalRange\": \"< 5.7%\",\n"
            "  \"illustrationIcon\": \"insights_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'bmi':
      case 'body_mass_index':
        return "### ⚖️ Body Mass Index (BMI)\n\n"
            "• **What it is:** An estimate of body composition based on weight (kg) divided by height squared (m²).\n"
            "• **Categories:**\n"
            "  - **Underweight:** < 18.5\n"
            "  - **Normal:** 18.5 to 24.9\n"
            "  - **Overweight:** 25.0 to 29.9\n"
            "  - **Obesity:** ≥ 30.0\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Body Mass Index (BMI)\",\n"
            "  \"definition\": \"Weight-to-height ratio used for general body mass screening.\",\n"
            "  \"normalRange\": \"18.5 - 24.9\",\n"
            "  \"illustrationIcon\": \"fitness_center_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      case 'pulse':
      case 'heart_rate':
        return "### 💓 Resting Heart Rate (Pulse)\n\n"
            "• **What it is:** Number of times your heart contracts per minute while in a relaxed, resting state.\n"
            "• **Normal Adult Range:** **60 to 100 BPM** (well-trained athletes often rest at 40–60 BPM).\n"
            "• **Variability:** Hydration, stress, caffeine, fever, and medications influence heart rate.\n\n"
            "```json\n"
            "{\n"
            "  \"type\": \"education_card\",\n"
            "  \"title\": \"Resting Heart Rate\",\n"
            "  \"definition\": \"Cardiac contractions per minute at rest.\",\n"
            "  \"normalRange\": \"60 - 100 BPM\",\n"
            "  \"illustrationIcon\": \"favorite_rounded\"\n"
            "}\n"
            "```\n\n$disclaimer";

      default:
        return "Regular tracking of your health vitals and understanding clinical concepts empowers you to take control of your well-being.\n\n$disclaimer";
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
        lower.contains('my data') ||
        lower.contains('my readings') ||
        lower.contains('my records') ||
        lower.contains('pattern');

    if (isTrendOrChartQuery) return null;

    final isExplanationIntent = lower.contains('what is') ||
        lower.contains('what does') ||
        lower.contains('meaning') ||
        lower.contains('definition') ||
        lower.contains('explain') ||
        lower.contains('what are');

    if (!isExplanationIntent) return null;

    if (lower.contains('spo2') || lower.contains('oxygen')) {
      return explainMetric('spo2');
    } else if (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('hypertension')) {
      return explainMetric('blood_pressure');
    } else if (lower.contains('glucose') || lower.contains('sugar') || lower.contains('diabetes')) {
      return explainMetric('glucose');
    } else if (lower.contains('cholesterol') || lower.contains('ldl') || lower.contains('hdl') || lower.contains('lipid')) {
      return explainMetric('cholesterol');
    } else if (lower.contains('a1c') || lower.contains('hba1c')) {
      return explainMetric('a1c');
    } else if (lower.contains('bmi') || lower.contains('body mass')) {
      return explainMetric('bmi');
    } else if (lower.contains('pulse') || lower.contains('heart rate') || lower.contains('bpm')) {
      return explainMetric('pulse');
    }
    return null;
  }
}
