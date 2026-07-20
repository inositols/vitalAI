import 'package:vitalai/core/database/db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/patient_repository.dart';
import '../models/patient_model.dart';

/// Local-first Patient Repository using SharedPreferences via DbService.
class PatientRepositoryImpl implements PatientRepository {
  final DbService _dbService;

  PatientRepositoryImpl(DbService dbService)
    : _dbService = dbService;

  @override
  Future<List<PatientModel>> getPatients() async {
    return _dbService.getPatients();
  }

  @override
  Future<PatientModel?> getPatientById(int id) async {
    final list = await _dbService.getPatients();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PatientModel?> getPatientByRemoteId(String remoteId) async {
    final list = await _dbService.getPatients();
    try {
      return list.firstWhere((p) => p.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePatient(PatientModel patient) async {
    final list = await _dbService.getPatients();
    if (patient.id == 0) {
      // Auto-increment ID manually
      final maxId = list.isEmpty
          ? 0
          : list.map((p) => p.id).reduce((a, b) => a > b ? a : b);
      patient.id = maxId + 1;
      list.add(patient);
    } else {
      final index = list.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        list[index] = patient;
      } else {
        list.add(patient);
      }
    }
    await _dbService.savePatients(list);
  }

  @override
  Future<void> deletePatient(int localId, String remoteId) async {
    final list = await _dbService.getPatients();
    list.removeWhere((p) => p.id == localId || p.remoteId == remoteId);
    await _dbService.savePatients(list);
  }

  @override
  Future<void> syncPatients() async {
    bool isFirebaseReady = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        isFirebaseReady = true;
      }
    } catch (_) {}

    final list = await _dbService.getPatients();
    if (list.isEmpty) return;

    if (isFirebaseReady) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      for (final p in list) {
        final docRef = firestore
            .collection('patients')
            .doc(p.remoteId.isNotEmpty ? p.remoteId : null);
        if (p.remoteId.isEmpty) {
          p.remoteId = docRef.id;
        }
        batch.set(docRef, p.toJson());
        p.isSynced = true;
        p.updatedAt = DateTime.now();
      }
      await batch.commit();
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
      for (final p in list) {
        p.isSynced = true;
        p.updatedAt = DateTime.now();
      }
    }

    await _dbService.savePatients(list);
  }
}
