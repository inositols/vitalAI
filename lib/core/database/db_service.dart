import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/patients/data/models/patient_model.dart';
import '../../features/vitals/data/models/vital_record.dart';
import '../../features/ai_assistant/data/models/chat_conversation.dart';
import '../../features/reminders/data/models/reminder_model.dart';

import '../../features/activity/data/models/activity_item.dart';
import '../../features/patients/data/models/clinical_note.dart';

/// Service responsible for managing local key-value database using SharedPreferences.
class DbService {
  final FlutterSecureStorage secureStorage;
  SharedPreferences? _prefs;

  DbService(this.secureStorage);

  /// Initialize SharedPreferences.
  Future<void> init({dynamic additionalSchemas}) async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Retrieve all patient profiles.
  Future<List<PatientModel>> getPatients() async {
    final raw = _prefs?.getString('patients');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all patient profiles.
  Future<void> savePatients(List<PatientModel> patients) async {
    final raw = jsonEncode(patients.map((p) => p.toJson()).toList());
    await _prefs?.setString('patients', raw);
  }

  /// Retrieve all vitals records.
  Future<List<VitalRecord>> getVitals() async {
    final raw = _prefs?.getString('vitals');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => VitalRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all vitals records.
  Future<void> saveVitals(List<VitalRecord> vitals) async {
    final raw = jsonEncode(vitals.map((v) => v.toJson()).toList());
    await _prefs?.setString('vitals', raw);
  }

  /// Retrieve all chat conversations for a specific patient.
  Future<List<ChatConversation>> getConversations(int patientId) async {
    final raw = _prefs?.getString('ai_conversations_$patientId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => ChatConversation.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all chat conversations for a specific patient.
  Future<void> saveConversations(int patientId, List<ChatConversation> conversations) async {
    final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await _prefs?.setString('ai_conversations_$patientId', raw);
  }

  /// Clear all conversations for a specific patient.
  Future<void> clearConversations(int patientId) async {
    await _prefs?.remove('ai_conversations_$patientId');
  }

  /// Retrieve all health reminders for a specific patient profile.
  Future<List<ReminderModel>> getReminders(int patientId) async {
    final raw = _prefs?.getString('reminders_$patientId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => ReminderModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Check if reminders key has been initialized for a patient profile.
  bool hasRemindersInitialized(int patientId) {
    return _prefs?.containsKey('reminders_$patientId') ?? false;
  }

  /// Save all health reminders for a specific patient profile.
  Future<void> saveReminders(int patientId, List<ReminderModel> reminders) async {
    final raw = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await _prefs?.setString('reminders_$patientId', raw);
  }

  /// Retrieve all clinical activities.
  Future<List<ActivityItem>> getActivities() async {
    final raw = _prefs?.getString('activities_log');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => ActivityItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all clinical activities.
  Future<void> saveActivities(List<ActivityItem> activities) async {
    final raw = jsonEncode(activities.map((a) => a.toJson()).toList());
    await _prefs?.setString('activities_log', raw);
  }

  /// Retrieve clinical notes for a patient.
  Future<List<ClinicalNote>> getClinicalNotes(int patientId) async {
    final raw = _prefs?.getString('clinical_notes_$patientId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => ClinicalNote.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save clinical notes for a patient.
  Future<void> saveClinicalNotes(int patientId, List<ClinicalNote> notes) async {
    final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _prefs?.setString('clinical_notes_$patientId', raw);
  }

  /// Clear database contents.
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
