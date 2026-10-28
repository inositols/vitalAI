import 'package:flutter/material.dart';

enum ClinicalIntent {
  recordBloodPressure,
  compareVitalReadings,
  listPatients,
  getPatientVitals,
  getPatientDetails,
  draftClinicalNote,
  getRecentActivity,
  createPatient,
  generalClinicalQuery,
}

class ClinicalFunctionResult {
  final ClinicalIntent intent;
  final String responseText;
  final Widget? embeddedComponent;
  final Map<String, dynamic> arguments;

  ClinicalFunctionResult({
    required this.intent,
    required this.responseText,
    this.embeddedComponent,
    this.arguments = const {},
  });
}

/// Dispatches provider voice/text requests to authorized application functions.
class ClinicalFunctionRouter {
  static ClinicalIntent classify(String query) {
    final lower = query.toLowerCase();

    // 0. Patient creation (voice or text)
    if (lower.contains('create a new patient') ||
        lower.contains('create patient') ||
        lower.contains('create a patient') ||
        lower.contains('add a new patient') ||
        lower.contains('add a patient') ||
        lower.contains('register a patient') ||
        lower.contains('register patient') ||
        lower.contains('start creating a patient') ||
        lower.contains('record for someone i just saw') ||
        (lower.startsWith('add ') && lower.contains('patient')) ||
        (lower.startsWith('create ') && !lower.contains('note') && !lower.contains('chart'))) {
      return ClinicalIntent.createPatient;
    }

    // 1. Record vital signs
    if ((lower.contains('record') || lower.contains('log') || lower.contains('add')) &&
        (lower.contains('blood pressure') || lower.contains('bp') || lower.contains('reading') || RegExp(r'\d{2,3}\s*(over|/)\s*\d{2,3}').hasMatch(lower))) {
      return ClinicalIntent.recordBloodPressure;
    }

    // 2. Compare readings / trend
    if (lower.contains('compare') || lower.contains('trend') || lower.contains('last week to this week') || lower.contains('last seven days') || lower.contains('7 days')) {
      return ClinicalIntent.compareVitalReadings;
    }

    // 3. Draft note
    if (lower.contains('draft') || lower.contains('clinical note') || lower.contains('note for my current visit') || lower.contains('add note')) {
      return ClinicalIntent.draftClinicalNote;
    }

    // 4. Open patient vitals
    if (lower.contains('vitals') || lower.contains('latest vital signs') || lower.contains('latest vitals') || lower.contains("open chika's")) {
      return ClinicalIntent.getPatientVitals;
    }

    // 5. List patients
    if (lower.contains('patients') || lower.contains('follow up') || lower.contains('high blood pressure')) {
      return ClinicalIntent.listPatients;
    }

    // 6. Recent activity
    if (lower.contains('activity') || lower.contains('recent interactions') || lower.contains('what did i do')) {
      return ClinicalIntent.getRecentActivity;
    }

    return ClinicalIntent.generalClinicalQuery;
  }

  /// Extracts blood pressure numbers (e.g. "118 over 76", "118/76")
  static Map<String, double>? extractBloodPressure(String query) {
    final slashRegex = RegExp(r'(\d{2,3})\s*/\s*(\d{2,3})');
    final overRegex = RegExp(r'(\d{2,3})\s*(?:over)\s*(\d{2,3})', caseSensitive: false);

    var match = overRegex.firstMatch(query) ?? slashRegex.firstMatch(query);
    if (match != null) {
      final sys = double.tryParse(match.group(1)!);
      final dia = double.tryParse(match.group(2)!);
      if (sys != null && dia != null) {
        return {'systolic': sys, 'diastolic': dia};
      }
    }
    return null;
  }
}
