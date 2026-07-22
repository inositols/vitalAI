import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';
import '../../data/models/health_context.dart';

/// HealthContextService is responsible for gathering patient data,
/// calculating recent vital trends, formatting AI health context payloads,
/// and dynamically generating smart suggestions.
class HealthContextService {
  final PatientRepository patientRepository;
  final VitalsRepository vitalsRepository;

  HealthContextService({
    required this.patientRepository,
    required this.vitalsRepository,
  });

  /// Builds a complete HealthContext payload for the given patient ID.
  Future<HealthContext> buildHealthContext(
    int patientId, {
    Duration dateWindow = const Duration(days: 30),
  }) async {
    final patients = await patientRepository.getPatients();
    final patient = patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => patients.isNotEmpty ? patients.first : throw Exception('Patient not found'),
    );

    final now = DateTime.now();
    final startDate = now.subtract(dateWindow);
    final allVitals = await vitalsRepository.getVitals(patientId);

    // Sort vitals chronologically
    allVitals.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final windowVitals = allVitals
        .where((v) => v.dateTime.isAfter(startDate) || v.dateTime.isAtSameMomentAs(startDate))
        .toList();

    final targetVitals = windowVitals.isNotEmpty ? windowVitals : allVitals;

    // 1. Calculate metric trends
    final bpSystolic = _calculateTrend(targetVitals.map((v) => v.systolic).whereType<double>().toList());
    final bpDiastolic = _calculateTrend(targetVitals.map((v) => v.diastolic).whereType<double>().toList());
    final glucose = _calculateTrend(targetVitals.map((v) => v.glucoseValue).whereType<double>().toList());
    final pulse = _calculateTrend(targetVitals.map((v) => v.pulseRate).whereType<double>().toList());
    final spo2 = _calculateTrend(targetVitals.map((v) => v.oxygenSaturation).whereType<double>().toList());
    final temp = _calculateTrend(targetVitals.map((v) => v.bodyTemperature).whereType<double>().toList());
    final weight = _calculateTrend(targetVitals.map((v) => v.weight).whereType<double>().toList());
    final bmi = _calculateTrend(targetVitals.map((v) => v.bmi).whereType<double>().toList());

    // 2. Extract symptoms & notes
    final symptoms = <String>[];
    for (var v in targetVitals.reversed) {
      if (v.note != null && v.note!.trim().isNotEmpty) {
        symptoms.add('[${_formatDate(v.dateTime)}] Note: ${v.note!.trim()}');
      }
      if (v.tags.isNotEmpty) {
        symptoms.add('[${_formatDate(v.dateTime)}] Tags: ${v.tags.join(', ')}');
      }
    }

    // 3. Compute Age
    final age = now.year - patient.dateOfBirth.year -
        ((now.month < patient.dateOfBirth.month ||
                (now.month == patient.dateOfBirth.month && now.day < patient.dateOfBirth.day))
            ? 1
            : 0);

    return HealthContext(
      patientId: patient.id,
      patientName: patient.name,
      gender: patient.gender,
      age: age > 0 ? age : 30,
      medicalNotes: patient.notes ?? '',
      conditions: patient.medicalConditions,
      allergies: patient.allergies,
      medications: patient.medications,
      bpSystolicTrend: bpSystolic,
      bpDiastolicTrend: bpDiastolic,
      glucoseTrend: glucose,
      pulseTrend: pulse,
      spo2Trend: spo2,
      tempTrend: temp,
      weightTrend: weight,
      bmiTrend: bmi,
      recentSymptoms: symptoms,
      totalVitalsCount: targetVitals.length,
      latestVitalDate: targetVitals.isNotEmpty ? targetVitals.last.dateTime : null,
    );
  }

  /// Dynamically generates smart contextual question suggestions.
  List<String> generateSmartSuggestions(HealthContext context) {
    final suggestions = <String>[];

    if (context.hasVitalsData) {
      suggestions.add('Summarise my health this week');
      suggestions.add('What changed in my recent readings?');
    }

    if (context.hasBpData) {
      suggestions.add('Analyse my blood pressure trend');
    }

    if (context.hasGlucoseData) {
      suggestions.add('Explain my glucose pattern');
    }

    if (context.hasPulseData || context.hasSpo2Data) {
      suggestions.add('Review my pulse and SpO₂ readings');
    }

    if (context.hasMedications) {
      suggestions.add('Review my medication adherence');
    }

    suggestions.add('Prepare questions for my doctor');
    suggestions.add('Review my latest health report');

    return suggestions.toSet().toList(); // Remove duplicates while preserving order
  }

  MetricTrend _calculateTrend(List<double> values) {
    if (values.isEmpty) {
      return const MetricTrend();
    }

    final totalReadings = values.length;
    final average = values.reduce((a, b) => a + b) / totalReadings;
    final highest = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);

    String direction = 'stable';
    if (totalReadings >= 2) {
      final mid = totalReadings ~/ 2;
      final olderSub = values.sublist(0, mid.clamp(1, totalReadings));
      final recentSub = values.sublist(mid);

      final olderAvg = olderSub.reduce((a, b) => a + b) / olderSub.length;
      final recentAvg = recentSub.reduce((a, b) => a + b) / recentSub.length;

      final diffPercent = (recentAvg - olderAvg) / (olderAvg == 0 ? 1 : olderAvg);
      if (diffPercent > 0.03) {
        direction = 'Increasing slightly';
      } else if (diffPercent < -0.03) {
        direction = 'Decreasing slightly';
      } else {
        direction = 'Stable';
      }
    }

    return MetricTrend(
      average: average,
      highest: highest,
      lowest: lowest,
      direction: direction,
      totalReadings: totalReadings,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
