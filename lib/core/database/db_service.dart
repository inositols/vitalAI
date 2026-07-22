import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/patients/data/models/patient_model.dart';
import '../../features/vitals/data/models/vital_record.dart';
import '../../features/ai_assistant/data/models/chat_conversation.dart';

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

  /// Clear database contents.
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
