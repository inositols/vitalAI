/// HealthMetricTrend represents trend analysis for a specific vital metric.
class MetricTrend {
  final double? average;
  final double? highest;
  final double? lowest;
  final String direction; // 'increasing', 'decreasing', 'stable', 'no_data'
  final int totalReadings;
  final String? secondaryAvg; // e.g. Diastolic avg for BP

  const MetricTrend({
    this.average,
    this.highest,
    this.lowest,
    this.direction = 'no_data',
    this.totalReadings = 0,
    this.secondaryAvg,
  });

  bool get hasData => totalReadings > 0;
}

/// HealthContext holds aggregated patient health records formatted for AI context.
class HealthContext {
  final int patientId;
  final String patientName;
  final String gender;
  final int age;
  final String medicalNotes;
  final List<String> conditions;
  final List<String> allergies;
  final List<String> medications;
  
  // Vital Trends
  final MetricTrend bpSystolicTrend;
  final MetricTrend bpDiastolicTrend;
  final MetricTrend glucoseTrend;
  final MetricTrend pulseTrend;
  final MetricTrend spo2Trend;
  final MetricTrend tempTrend;
  final MetricTrend weightTrend;
  final MetricTrend bmiTrend;

  // Recent History
  final List<String> recentSymptoms; // derived from notes/tags
  final int totalVitalsCount;
  final DateTime? latestVitalDate;

  const HealthContext({
    required this.patientId,
    required this.patientName,
    required this.gender,
    required this.age,
    required this.medicalNotes,
    required this.conditions,
    required this.allergies,
    required this.medications,
    required this.bpSystolicTrend,
    required this.bpDiastolicTrend,
    required this.glucoseTrend,
    required this.pulseTrend,
    required this.spo2Trend,
    required this.tempTrend,
    required this.weightTrend,
    required this.bmiTrend,
    required this.recentSymptoms,
    required this.totalVitalsCount,
    this.latestVitalDate,
  });

  /// Check whether any vitals readings are present.
  bool get hasVitalsData => totalVitalsCount > 0;

  /// Check presence of specific vital categories
  bool get hasBpData => bpSystolicTrend.hasData;
  bool get hasGlucoseData => glucoseTrend.hasData;
  bool get hasPulseData => pulseTrend.hasData;
  bool get hasSpo2Data => spo2Trend.hasData;
  bool get hasTempData => tempTrend.hasData;
  bool get hasWeightData => weightTrend.hasData;
  bool get hasMedications => medications.isNotEmpty;

  /// Compiles a clean, AI-friendly context summary string.
  String toAiContextString() {
    final buffer = StringBuffer();
    buffer.writeln('Patient Health Profile & Vitals Context:');
    buffer.writeln('- Name: $patientName, Gender: $gender, Age: $age');
    if (conditions.isNotEmpty) {
      buffer.writeln('- Medical Conditions: ${conditions.join(', ')}');
    }
    if (allergies.isNotEmpty) {
      buffer.writeln('- Known Allergies: ${allergies.join(', ')}');
    }
    if (medications.isNotEmpty) {
      buffer.writeln('- Current Medications: ${medications.join(', ')}');
    }
    if (medicalNotes.isNotEmpty) {
      buffer.writeln('- Profile Notes: $medicalNotes');
    }
    
    buffer.writeln('\nVitals Trend Summary (Recent Records):');

    if (hasBpData) {
      final sysAvg = bpSystolicTrend.average?.toStringAsFixed(0) ?? 'N/A';
      final diaAvg = bpDiastolicTrend.average?.toStringAsFixed(0) ?? 'N/A';
      final sysHigh = bpSystolicTrend.highest?.toStringAsFixed(0) ?? 'N/A';
      final diaHigh = bpDiastolicTrend.highest?.toStringAsFixed(0) ?? 'N/A';
      final sysLow = bpSystolicTrend.lowest?.toStringAsFixed(0) ?? 'N/A';
      final diaLow = bpDiastolicTrend.lowest?.toStringAsFixed(0) ?? 'N/A';
      buffer.writeln(
        '- Blood Pressure:\n'
        '  • Average: $sysAvg/$diaAvg mmHg\n'
        '  • Highest: $sysHigh/$diaHigh mmHg\n'
        '  • Lowest: $sysLow/$diaLow mmHg\n'
        '  • Trend: ${bpSystolicTrend.direction}',
      );
    } else {
      buffer.writeln('- Blood Pressure: No readings recorded.');
    }

    if (hasGlucoseData) {
      final avg = glucoseTrend.average?.toStringAsFixed(1) ?? 'N/A';
      final high = glucoseTrend.highest?.toStringAsFixed(1) ?? 'N/A';
      final low = glucoseTrend.lowest?.toStringAsFixed(1) ?? 'N/A';
      buffer.writeln(
        '- Glucose:\n'
        '  • Average: $avg mg/dL\n'
        '  • Highest: $high mg/dL\n'
        '  • Lowest: $low mg/dL\n'
        '  • Trend: ${glucoseTrend.direction}',
      );
    } else {
      buffer.writeln('- Glucose: No readings recorded.');
    }

    if (hasPulseData) {
      final avg = pulseTrend.average?.toStringAsFixed(0) ?? 'N/A';
      final high = pulseTrend.highest?.toStringAsFixed(0) ?? 'N/A';
      final low = pulseTrend.lowest?.toStringAsFixed(0) ?? 'N/A';
      buffer.writeln(
        '- Pulse / Heart Rate: Avg $avg BPM (Min $low, Max $high, Trend: ${pulseTrend.direction})',
      );
    }

    if (hasSpo2Data) {
      final avg = spo2Trend.average?.toStringAsFixed(1) ?? 'N/A';
      final low = spo2Trend.lowest?.toStringAsFixed(1) ?? 'N/A';
      buffer.writeln(
        '- Oxygen Saturation (SpO₂): Avg $avg% (Lowest: $low%, Trend: ${spo2Trend.direction})',
      );
    }

    if (hasTempData) {
      final avg = tempTrend.average?.toStringAsFixed(1) ?? 'N/A';
      buffer.writeln('- Temperature: Avg $avg°C');
    }

    if (hasWeightData) {
      final avgW = weightTrend.average?.toStringAsFixed(1) ?? 'N/A';
      final avgBmi = bmiTrend.average?.toStringAsFixed(1) ?? 'N/A';
      buffer.writeln(
        '- Weight & BMI: Latest Avg Weight $avgW kg, BMI $avgBmi (Trend: ${weightTrend.direction})',
      );
    }

    if (recentSymptoms.isNotEmpty) {
      buffer.writeln('\nRecorded Symptoms & Notes History:');
      for (var s in recentSymptoms.take(5)) {
        buffer.writeln('  • $s');
      }
    }

    return buffer.toString();
  }
}
