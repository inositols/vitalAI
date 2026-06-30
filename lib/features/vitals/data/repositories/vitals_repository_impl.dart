import 'package:vitalai/core/database/db_service.dart';

import '../../domain/repositories/vitals_repository.dart';
import '../models/vital_record.dart';

/// Local-first Vitals Repository using SharedPreferences via DbService.
class VitalsRepositoryImpl implements VitalsRepository {
  final DbService _dbService;

  VitalsRepositoryImpl(dynamic dbService) : _dbService = dbService as DbService;

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
      filtered = filtered.where(
        (v) =>
            v.dateTime.isBefore(endDate) ||
            v.dateTime.isAtSameMomentAs(endDate),
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
    // Simulated cloud sync stub
    return;
  }

  bool _matchesType(VitalRecord r, String type) {
    switch (type) {
      case 'blood_pressure':
        return r.systolic != null || r.diastolic != null;
      case 'glucose':
        return r.glucoseValue != null;
      case 'pulse':
        return r.pulseRate != null;
      case 'oxygen':
        return r.oxygenSaturation != null;
      case 'temperature':
        return r.bodyTemperature != null;
      case 'weight':
        return r.weight != null;
      default:
        return false;
    }
  }

  bool _isAbnormal(VitalRecord r) {
    if (r.systolic != null && (r.systolic! >= 130 || r.systolic! < 90))
      return true;
    if (r.diastolic != null && (r.diastolic! >= 85 || r.diastolic! < 60))
      return true;
    if (r.oxygenSaturation != null && r.oxygenSaturation! < 95) return true;
    if (r.glucoseValue != null &&
        (r.glucoseValue! >= 140 || r.glucoseValue! < 70))
      return true;
    return false;
  }
}
