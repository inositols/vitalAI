import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/patients/data/models/patient_model.dart';
import '../../features/vitals/data/models/vital_record.dart';

/// Service responsible for managing local key-value database using SharedPreferences.
class DbService {
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  DbService(this._secureStorage);

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

  /// Clear database contents.
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

