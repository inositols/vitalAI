import '../../features/vitals/data/models/vital_record.dart';

/// Analyzes health vitals log trends (weekly/monthly), blood pressure patterns,
/// weight/glucose changes, and generates humanized, concise educational summaries.
class AiTrendAnalyzer {
  /// Generates a concise trend summary from historical records.
  static String generateTrendSummary({
    required List<VitalRecord> records,
    int periodDays = 14,
  }) {
    if (records.isEmpty) {
      return "No vital readings recorded in the past $periodDays days. Keep recording consistently to unlock intelligent AI trend insights!";
    }

    final bpRecords = records.where((r) => r.systolic != null || r.diastolic != null).toList();
    final glucoseRecords = records.where((r) => r.glucoseValue != null).toList();
    final weightRecords = records.where((r) => r.weight != null).toList();
    final pulseRecords = records.where((r) => r.pulseRate != null).toList();

    final buffer = StringBuffer();

    if (bpRecords.isNotEmpty) {
      final avgSystolic = bpRecords.map((r) => r.systolic ?? 120.0).reduce((a, b) => a + b) / bpRecords.length;
      if (avgSystolic < 120) {
        buffer.write("Your blood pressure has remained in a healthy resting range over the past two weeks. ");
      } else if (avgSystolic < 135) {
        buffer.write("Your blood pressure shows mild elevation averaging ${avgSystolic.round()} mmHg. ");
      } else {
        buffer.write("Your blood pressure readings have averaged above 135 mmHg systolic. ");
      }
    }

    if (glucoseRecords.isNotEmpty) {
      final avgGlucose = glucoseRecords.map((r) => r.glucoseValue!).reduce((a, b) => a + b) / glucoseRecords.length;
      if (avgGlucose > 110) {
        buffer.write("Fasting glucose readings remain slightly above your previous average (avg ${avgGlucose.round()} mg/dL). ");
      } else {
        buffer.write("Fasting glucose readings are consistent and stable. ");
      }
    }

    if (weightRecords.length >= 2) {
      final diff = weightRecords.first.weight! - weightRecords.last.weight!;
      if (diff.abs() > 0.5) {
        final direction = diff > 0 ? "increased" : "decreased";
        buffer.write("Your weight has $direction by ${diff.abs().toStringAsFixed(1)} kg recently. ");
      }
    }

    if (pulseRecords.isNotEmpty) {
      final avgPulse = pulseRecords.map((r) => r.pulseRate!).reduce((a, b) => a + b) / pulseRecords.length;
      buffer.write("Resting pulse rate averages ${avgPulse.round()} BPM. ");
    }

    if (buffer.isEmpty) {
      return "You have recorded ${records.length} health measurements in the past $periodDays days. Keep up the consistent monitoring!";
    }

    buffer.write("\n\nEducational Tip: Continue tracking at similar times daily for maximum consistency.");
    return buffer.toString().trim();
  }

  /// Returns educational recommendations based on vital history.
  static List<String> generateEducationalRecommendations(List<VitalRecord> records) {
    final recommendations = <String>[];

    if (records.isEmpty) {
      recommendations.add("Record your first vital reading today to track your health progress.");
      recommendations.add("Set up daily reminder alerts in settings to maintain logging habits.");
      return recommendations;
    }

    recommendations.add("Drink plenty of water (8+ glasses daily) to support hydration and kidney function.");
    recommendations.add("Maintain consistent daily logging times for reliable trend analysis.");

    final bpRecords = records.where((r) => r.systolic != null || r.diastolic != null).toList();
    if (bpRecords.length < 3) {
      recommendations.add("Record blood pressure at least 3-4 times a week to establish a reliable baseline.");
    } else {
      recommendations.add("Schedule regular check-ins with your healthcare provider to review your BP logs.");
    }

    return recommendations;
  }
}
