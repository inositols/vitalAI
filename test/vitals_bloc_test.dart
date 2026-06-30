import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';
import 'package:vitalai/features/vitals/presentation/bloc/vitals_bloc.dart';
import 'package:vitalai/features/vitals/presentation/bloc/vitals_event.dart';
import 'package:vitalai/features/vitals/presentation/bloc/vitals_state.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';

class MockVitalsRepository extends Mock implements VitalsRepository {}

void main() {
  late MockVitalsRepository mockVitalsRepository;
  late VitalsBloc vitalsBloc;

  setUp(() {
    mockVitalsRepository = MockVitalsRepository();
    vitalsBloc = VitalsBloc(vitalsRepository: mockVitalsRepository);
  });

  tearDown(() {
    vitalsBloc.close();
  });

  group('VitalsBloc Tests', () {
    final testRecord = VitalRecord()
      ..id = 1
      ..remoteId = 'rec_123'
      ..patientId = 1
      ..dateTime = DateTime(2026, 6, 30, 12, 0)
      ..systolic = 120
      ..diastolic = 80
      ..pulseRate = 72
      ..isSynced = false
      ..updatedAt = DateTime(2026, 6, 30, 12, 0);

    test('initial state should be VitalsInitial', () {
      expect(vitalsBloc.state, equals(VitalsInitial()));
    });

    blocTest<VitalsBloc, VitalsState>(
      'emits [VitalsLoading, VitalsLoadSuccess] when VitalsListRequested succeeds',
      build: () {
        when(() => mockVitalsRepository.getVitals(any()))
            .thenAnswer((_) async => [testRecord]);
        return vitalsBloc;
      },
      act: (bloc) => bloc.add(const VitalsListRequested(1)),
      expect: () => [
        VitalsLoading(),
        VitalsLoadSuccess([testRecord]),
      ],
    );

    blocTest<VitalsBloc, VitalsState>(
      'emits [VitalsLoading, VitalsFailure] when VitalsListRequested throws exception',
      build: () {
        when(() => mockVitalsRepository.getVitals(any()))
            .thenThrow(Exception('Database error'));
        return vitalsBloc;
      },
      act: (bloc) => bloc.add(const VitalsListRequested(1)),
      expect: () => [
        VitalsLoading(),
        const VitalsFailure('Exception: Database error'),
      ],
    );

    blocTest<VitalsBloc, VitalsState>(
      'emits [VitalsLoading, VitalsLoadSuccess] when VitalsRecordSaved succeeds',
      build: () {
        // Register mock tail fallback value
        registerFallbackValue(testRecord);
        when(() => mockVitalsRepository.saveVitalRecord(any()))
            .thenAnswer((_) async {});
        when(() => mockVitalsRepository.getVitals(any()))
            .thenAnswer((_) async => [testRecord]);
        return vitalsBloc;
      },
      act: (bloc) => bloc.add(VitalsRecordSaved(testRecord)),
      expect: () => [
        VitalsLoading(),
        VitalsLoadSuccess([testRecord]),
      ],
    );
   group('Vitals Filter Tests', () {
      blocTest<VitalsBloc, VitalsState>(
        'emits [VitalsLoading, VitalsLoadSuccess] when VitalsFilteredRequested succeeds',
        build: () {
          when(() => mockVitalsRepository.getFilteredVitals(
                patientId: any(named: 'patientId'),
                vitalType: any(named: 'vitalType'),
                startDate: any(named: 'startDate'),
                endDate: any(named: 'endDate'),
                abnormalOnly: any(named: 'abnormalOnly'),
              )).thenAnswer((_) async => [testRecord]);
          return vitalsBloc;
        },
        act: (bloc) => bloc.add(const VitalsFilteredRequested(
          patientId: 1,
          vitalType: 'blood_pressure',
        )),
        expect: () => [
          VitalsLoading(),
          VitalsLoadSuccess([testRecord]),
        ],
      );
    });
  });
}
