import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/database/db_service.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/data/repositories/vitals_repository_impl.dart';

class MockDbService implements DbService {
  final List<VitalRecord> _records = [];

  void addRecord(VitalRecord r) {
    _records.add(r);
  }

  @override
  Future<List<VitalRecord>> getVitals() async => _records;

  @override
  Future<void> saveVitals(List<VitalRecord> list) async {
    _records.clear();
    _records.addAll(list);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Vitals Repository Filtering Tests', () {
    late MockDbService mockDb;
    late VitalsRepositoryImpl repo;

    setUp(() {
      mockDb = MockDbService();
      repo = VitalsRepositoryImpl(mockDb);

      mockDb.addRecord(
        VitalRecord()
          ..id = 1
          ..patientId = 101
          ..dateTime = DateTime.now()
          ..systolic = 120
          ..diastolic = 80,
      );

      mockDb.addRecord(
        VitalRecord()
          ..id = 2
          ..patientId = 101
          ..dateTime = DateTime.now()
          ..glucoseValue = 95,
      );

      mockDb.addRecord(
        VitalRecord()
          ..id = 3
          ..patientId = 101
          ..dateTime = DateTime.now()
          ..oxygenSaturation = 98,
      );
    });

    test('Filters Blood Pressure correctly using "bp" filter key', () async {
      final bpRecords = await repo.getFilteredVitals(
        patientId: 101,
        vitalType: 'bp',
      );

      expect(bpRecords.length, 1);
      expect(bpRecords.first.systolic, 120);
      expect(bpRecords.first.diastolic, 80);
    });

    test('Filters SpO2 correctly using "spo2" filter key', () async {
      final spo2Records = await repo.getFilteredVitals(
        patientId: 101,
        vitalType: 'spo2',
      );

      expect(spo2Records.length, 1);
      expect(spo2Records.first.oxygenSaturation, 98);
    });
  });
}
