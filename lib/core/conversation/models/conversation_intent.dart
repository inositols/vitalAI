import 'package:flutter/material.dart';

/// Clinical conversational intents supported across VitalAI / VoiceVitals.
enum ConversationIntent {
  /// Record one or more vital sign observations (blood pressure, heart rate, temperature, etc.)
  recordVitals,

  /// Compare vital sign observations across dates or time periods
  compareVitals,

  /// Register/create a new patient profile
  createPatient,

  /// Search and resolve patient identities when ambiguous
  findPatient,

  /// Open patient profile chart and clinical overview
  openPatientDetails,

  /// Update existing patient record details (e.g. phone, contact, conditions)
  updatePatientInfo,

  /// Draft, review, edit, and save clinical visit/encounter notes
  draftClinicalNote,

  /// Create, reschedule, or cancel patient appointments and follow-up reminders
  manageAppointments,

  /// Query patient longitudinal history, summaries, notes, or vitals
  queryPatientHistory,

  /// General clinical query or fallback
  generalQuery,
}

extension ConversationIntentX on ConversationIntent {
  String get displayName {
    switch (this) {
      case ConversationIntent.recordVitals:
        return 'Record Vital Signs';
      case ConversationIntent.compareVitals:
        return 'Compare Vital Readings';
      case ConversationIntent.createPatient:
        return 'Create Patient';
      case ConversationIntent.findPatient:
        return 'Find Patient';
      case ConversationIntent.openPatientDetails:
        return 'Patient Details';
      case ConversationIntent.updatePatientInfo:
        return 'Update Patient Info';
      case ConversationIntent.draftClinicalNote:
        return 'Draft Clinical Note';
      case ConversationIntent.manageAppointments:
        return 'Follow-ups & Appointments';
      case ConversationIntent.queryPatientHistory:
        return 'Patient History & Summaries';
      case ConversationIntent.generalQuery:
        return 'Clinical Assistant';
    }
  }

  IconData get icon {
    switch (this) {
      case ConversationIntent.recordVitals:
        return Icons.favorite_rounded;
      case ConversationIntent.compareVitals:
        return Icons.insights_rounded;
      case ConversationIntent.createPatient:
        return Icons.person_add_rounded;
      case ConversationIntent.findPatient:
        return Icons.search_rounded;
      case ConversationIntent.openPatientDetails:
        return Icons.badge_rounded;
      case ConversationIntent.updatePatientInfo:
        return Icons.edit_note_rounded;
      case ConversationIntent.draftClinicalNote:
        return Icons.description_rounded;
      case ConversationIntent.manageAppointments:
        return Icons.calendar_today_rounded;
      case ConversationIntent.queryPatientHistory:
        return Icons.history_edu_rounded;
      case ConversationIntent.generalQuery:
        return Icons.smart_toy_rounded;
    }
  }

  /// Whether this intent performs a consequential database write requiring explicit provider confirmation.
  bool get isConsequentialWrite {
    switch (this) {
      case ConversationIntent.recordVitals:
      case ConversationIntent.createPatient:
      case ConversationIntent.updatePatientInfo:
      case ConversationIntent.draftClinicalNote:
      case ConversationIntent.manageAppointments:
        return true;
      case ConversationIntent.compareVitals:
      case ConversationIntent.findPatient:
      case ConversationIntent.openPatientDetails:
      case ConversationIntent.queryPatientHistory:
      case ConversationIntent.generalQuery:
        return false;
    }
  }
}
