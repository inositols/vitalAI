import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/widgets/app_card.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/settings/presentation/bloc/settings_state.dart';
import '../features/vitals/data/models/vital_record.dart';
import '../features/vitals/domain/repositories/vitals_repository.dart';
import '../features/vitals/presentation/bloc/vitals_bloc.dart';
import '../features/vitals/presentation/bloc/vitals_state.dart';
import '../features/vitals/presentation/widgets/vital_record_card.dart';
import '../features/vitals/presentation/widgets/vitals_metric_card.dart';

class MockVitalsRepository implements VitalsRepository {
  @override
  Future<List<VitalRecord>> getVitals(int patientId) async => _mockRecords;

  @override
  Future<List<VitalRecord>> getFilteredVitals({
    required int patientId,
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    bool? abnormalOnly,
  }) async => _mockRecords;

  @override
  Future<void> saveVitalRecord(VitalRecord record) async {}

  @override
  Future<void> deleteVitalRecord(int localId, String remoteId) async {}

  @override
  Future<void> syncVitals() async {}

  List<VitalRecord> get _mockRecords => [
        VitalRecord()
          ..id = 1
          ..patientId = 1
          ..remoteId = 'v1'
          ..dateTime = DateTime.now()
          ..systolic = 120
          ..diastolic = 80
          ..glucoseValue = 95
          ..pulseRate = 72
          ..oxygenSaturation = 98
          ..bodyTemperature = 36.6
          ..weight = 70
          ..isSynced = true
          ..updatedAt = DateTime.now(),
      ];
}

class FakeVitalsBloc extends VitalsBloc {
  FakeVitalsBloc() : super(vitalsRepository: MockVitalsRepository());

  @override
  VitalsState get state => VitalsLoadSuccess(MockVitalsRepository()._mockRecords);
}

class FakeSettingsBloc extends SettingsBloc {
  FakeSettingsBloc() : super(secureStorage: const FlutterSecureStorage());

  @override
  SettingsState get state => const SettingsState();
}

WidgetbookFolder get cardStories {
  return WidgetbookFolder(
    name: 'Cards',
    children: [
      WidgetbookComponent(
        name: 'AppCard',
        useCases: [
          WidgetbookUseCase(
            name: 'Default AppCard',
            builder: (context) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Health Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('All vital metrics are currently within healthy baseline ranges.'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'VitalRecordCard',
        useCases: [
          WidgetbookUseCase(
            name: 'Logged Vitals Badge Card',
            builder: (context) {
              final record = VitalRecord()
                ..id = 1
                ..patientId = 1
                ..remoteId = 'v1'
                ..dateTime = DateTime.now()
                ..systolic = 120
                ..diastolic = 80
                ..glucoseValue = 95
                ..pulseRate = 72
                ..oxygenSaturation = 98
                ..weight = 70
                ..isSynced = true
                ..updatedAt = DateTime.now();

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: VitalRecordCard(
                    record: record,
                    onDelete: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'VitalsMetricCard',
        useCases: [
          WidgetbookUseCase(
            name: 'Blood Pressure Metric Summary Card',
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider<VitalsBloc>(create: (_) => FakeVitalsBloc()),
                  BlocProvider<SettingsBloc>(create: (_) => FakeSettingsBloc()),
                ],
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: VitalsMetricCard(
                      metricType: 'bp',
                      patientId: '1',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
