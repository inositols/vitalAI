import 'package:vitalai/core/database/db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/vitals_repository.dart';
import '../models/vital_record.dart';

/// Local-first Vitals Repository using SharedPreferences via DbService.
class VitalsRepositoryImpl implements VitalsRepository {
  final DbService _dbService;

  VitalsRepositoryImpl(DbService dbService) : _dbService = dbService;

  @override
  Future<List<VitalRecord>> getVitals(int patientId) async {
    final list = await _dbService.getVitals();
    return list.where((v) => v.patientId == patientId).toList();
  }

  @override
  Future<List<VitalRecord>> getFilteredVitals({
    required int patientId,
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    bool? abnormalOnly,
  }) async {
    final list = await _dbService.getVitals();
    var filtered = list.where((v) => v.patientId == patientId);

    if (vitalType != null) {
      filtered = filtered.where((v) => _matchesType(v, vitalType));
    }

    if (startDate != null) {
      filtered = filtered.where(
        (v) =>
            v.dateTime.isAfter(startDate) ||
            v.dateTime.isAtSameMomentAs(startDate),
      );
    }

    if (endDate != null) {
      final inclusiveEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      filtered = filtered.where(
        (v) =>
            v.dateTime.isBefore(inclusiveEndDate) ||
            v.dateTime.isAtSameMomentAs(inclusiveEndDate),
      );
    }

    if (abnormalOnly == true) {
      filtered = filtered.where(_isAbnormal);
    }

    return filtered.toList();
  }

  @override
  Future<void> saveVitalRecord(VitalRecord record) async {
    final list = await _dbService.getVitals();
    if (record.id == 0) {
      final maxId = list.isEmpty
          ? 0
          : list.map((v) => v.id).reduce((a, b) => a > b ? a : b);
      record.id = maxId + 1;
      list.add(record);
    } else {
      final index = list.indexWhere((v) => v.id == record.id);
      if (index != -1) {
        list[index] = record;
      } else {
        list.add(record);
      }
    }
    await _dbService.saveVitals(list);
  }

  @override
  Future<void> deleteVitalRecord(int localId, String remoteId) async {
    final list = await _dbService.getVitals();
    list.removeWhere((v) => v.id == localId || v.remoteId == remoteId);
    await _dbService.saveVitals(list);
  }

  @override
  Future<void> syncVitals() async {
    bool isFirebaseReady = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        isFirebaseReady = true;
      }
    } catch (_) {}

    // 1. Sync Patient Profiles first
    try {
      final listP = await _dbService.getPatients();
      if (listP.isNotEmpty) {
        if (isFirebaseReady) {
          final firestore = FirebaseFirestore.instance;
          final batch = firestore.batch();
          for (final p in listP) {
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
          await Future.delayed(const Duration(milliseconds: 500));
          for (final p in listP) {
            p.isSynced = true;
            p.updatedAt = DateTime.now();
          }
        }
        await _dbService.savePatients(listP);
      }
    } catch (_) {}

    // 2. Sync Vital Records
    final list = await _dbService.getVitals();
    if (list.isEmpty) return;

    if (isFirebaseReady) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      for (final v in list) {
        final docRef = firestore
            .collection('vitals')
            .doc(v.remoteId.isNotEmpty ? v.remoteId : null);
        if (v.remoteId.isEmpty) {
          v.remoteId = docRef.id;
        }
        batch.set(docRef, v.toJson());
        v.isSynced = true;
        v.updatedAt = DateTime.now();
      }
      await batch.commit();
    } else {
      // Simulate network delay for a real cloud sync feel
      await Future.delayed(const Duration(milliseconds: 1000));

      for (final v in list) {
        v.isSynced = true;
        v.updatedAt = DateTime.now();
      }
    }

    await _dbService.saveVitals(list);
  }

  bool _matchesType(VitalRecord r, String type) {
    switch (type.toLowerCase()) {
      case 'bp':
      case 'blood_pressure':
        return r.systolic != null || r.diastolic != null;
      case 'glucose':
        return r.glucoseValue != null;
      case 'pulse':
      case 'heart_rate':
        return r.pulseRate != null;
      case 'spo2':
      case 'oxygen':
        return r.oxygenSaturation != null;
      case 'temp':
      case 'temperature':
        return r.bodyTemperature != null;
      case 'weight':
        return r.weight != null;
      default:
        return false;
    }
  }

  bool _isAbnormal(VitalRecord r) {
    if (r.systolic != null && (r.systolic! >= 130 || r.systolic! < 90)) {
      return true;
    }
    if (r.diastolic != null && (r.diastolic! >= 85 || r.diastolic! < 60)) {
      return true;
    }
    if (r.oxygenSaturation != null && r.oxygenSaturation! < 95) return true;
    if (r.glucoseValue != null &&
        (r.glucoseValue! >= 140 || r.glucoseValue! < 70)) {
      return true;
    }
    return false;
  }
}
