import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vitalai/core/database/db_service.dart';
import 'package:vitalai/core/services/ai_service.dart';
import 'package:vitalai/core/genui/genui_parser.dart';
import 'package:vitalai/core/genui/models/genui_component_model.dart';
import 'package:vitalai/core/services/sync_engine.dart';
import 'package:vitalai/core/notifications/notification_service.dart';
import 'package:vitalai/features/ai_assistant/domain/services/health_context_service.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/data/repositories/patient_repository_impl.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/reminders/data/models/reminder_model.dart';
import 'package:vitalai/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:vitalai/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_event.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/data/repositories/vitals_repository_impl.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';
import 'package:flutter/material.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorage mockSecureStorage;
  late MockNotificationService mockNotificationService;
  late DbService dbService;
  late PatientRepository patientRepository;
  late VitalsRepository vitalsRepository;
  late ReminderRepository reminderRepository;
  late HealthContextService healthContextService;
  late AiService aiService;
  late SettingsBloc settingsBloc;

  final Map<String, String> inMemorySecureStore = {};
  final Map<String, dynamic> inMemoryDb = {};

  setUp(() async {
    inMemorySecureStore.clear();
    inMemoryDb.clear();

    mockSecureStorage = MockSecureStorage();
    mockNotificationService = MockNotificationService();
    when(() => mockNotificationService.scheduleDailyReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        )).thenAnswer((_) async {});
    when(() => mockNotificationService.cancelNotification(any())).thenAnswer((_) async {});

    when(() => mockSecureStorage.read(key: any(named: 'key')))
        .thenAnswer((inv) async => inMemorySecureStore[inv.namedArguments[#key] as String]);
    when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((inv) async {
      inMemorySecureStore[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => mockSecureStorage.delete(key: any(named: 'key')))
        .thenAnswer((inv) async {
      inMemorySecureStore.remove(inv.namedArguments[#key] as String);
    });

    SharedPreferences.setMockInitialValues({});
    dbService = DbService(mockSecureStorage);
    await dbService.init();
    patientRepository = PatientRepositoryImpl(dbService);
    vitalsRepository = VitalsRepositoryImpl(dbService);
    reminderRepository = ReminderRepositoryImpl(
      dbService: dbService,
      notificationService: mockNotificationService,
    );
    healthContextService = HealthContextService(
      patientRepository: patientRepository,
      vitalsRepository: vitalsRepository,
    );
    aiService = AiService('');

    settingsBloc = SettingsBloc(
      secureStorage: mockSecureStorage,
      initialState: const SettingsState(),
    );
  });

  group('End-to-End Cross-Feature User Flow Verification', () {
    test('Flow 1: Multi-Patient Isolation, Switching, and Profile CRUD', () async {
      // 1. Create Patient 1: Sarah Connor
      final patient1 = PatientModel()
        ..name = 'Sarah Connor'
        ..gender = 'Female'
        ..dateOfBirth = DateTime(1985, 4, 12)
        ..height = 168.0
        ..weight = 62.0
        ..medicalConditions = ['Hypertension']
        ..allergies = ['Penicillin']
        ..medications = ['Lisinopril 10mg'];

      await patientRepository.savePatient(patient1);
      final patientsAfterP1 = await patientRepository.getPatients();
      expect(patientsAfterP1.length, equals(1));
      expect(patientsAfterP1.first.name, equals('Sarah Connor'));
      final p1Id = patientsAfterP1.first.id;

      // 2. Create Patient 2: John Connor
      final patient2 = PatientModel()
        ..name = 'John Connor'
        ..gender = 'Male'
        ..dateOfBirth = DateTime(1995, 2, 28)
        ..height = 180.0
        ..weight = 75.0
        ..medicalConditions = []
        ..allergies = []
        ..medications = [];

      await patientRepository.savePatient(patient2);
      final patientsAfterP2 = await patientRepository.getPatients();
      expect(patientsAfterP2.length, equals(2));
      final p2 = patientsAfterP2.firstWhere((p) => p.name == 'John Connor');
      final p2Id = p2.id;
      expect(p1Id, isNot(equals(p2Id)));

      // 3. Update Patient 1 profile
      final p1ToUpdate = patientsAfterP2.firstWhere((p) => p.id == p1Id);
      p1ToUpdate.weight = 61.5;
      p1ToUpdate.medications = ['Lisinopril 10mg', 'Aspirin 81mg'];
      await patientRepository.savePatient(p1ToUpdate);

      final updatedPatients = await patientRepository.getPatients();
      final reloadedP1 = updatedPatients.firstWhere((p) => p.id == p1Id);
      expect(reloadedP1.weight, equals(61.5));
      expect(reloadedP1.medications, contains('Aspirin 81mg'));
    });

    test('Flow 2: Vital Recording, Validation, Filtering, and Patient Isolation', () async {
      // Setup Sarah (ID: 10) and John (ID: 20)
      final p1 = PatientModel()..id = 10..name = 'Sarah'..height = 168..weight = 62;
      final p2 = PatientModel()..id = 20..name = 'John'..height = 180..weight = 75;
      await patientRepository.savePatient(p1);
      await patientRepository.savePatient(p2);

      // Record BP for Sarah
      final v1 = VitalRecord()
        ..patientId = 10
        ..dateTime = DateTime.now().subtract(const Duration(hours: 2))
        ..systolic = 125.0
        ..diastolic = 82.0
        ..pulseRate = 72.0;
      await vitalsRepository.saveVitalRecord(v1);

      // Record Glucose for Sarah
      final v2 = VitalRecord()
        ..patientId = 10
        ..dateTime = DateTime.now().subtract(const Duration(hours: 1))
        ..glucoseValue = 98.0
        ..glucoseMealContext = 'fasting';
      await vitalsRepository.saveVitalRecord(v2);

      // Record SpO2 for John
      final v3 = VitalRecord()
        ..patientId = 20
        ..dateTime = DateTime.now()
        ..oxygenSaturation = 99.0
        ..pulseRate = 68.0;
      await vitalsRepository.saveVitalRecord(v3);

      // Verify Sarah's records contain only her vitals
      final sarahVitals = await vitalsRepository.getVitals(10);
      expect(sarahVitals.length, equals(2));
      expect(sarahVitals.any((v) => v.systolic == 125.0), isTrue);
      expect(sarahVitals.any((v) => v.glucoseValue == 98.0), isTrue);
      expect(sarahVitals.any((v) => v.oxygenSaturation == 99.0), isFalse);

      // Verify John's records contain only his vitals
      final johnVitals = await vitalsRepository.getVitals(20);
      expect(johnVitals.length, equals(1));
      expect(johnVitals.first.oxygenSaturation, equals(99.0));
      expect(johnVitals.any((v) => v.systolic == 125.0), isFalse);

      // Verify Filter by vitalType 'bp'
      final sarahBpFilter = await vitalsRepository.getFilteredVitals(
        patientId: 10,
        vitalType: 'bp',
      );
      expect(sarahBpFilter.length, equals(1));
      expect(sarahBpFilter.first.systolic, equals(125.0));

      // Verify Filter by vitalType 'glucose'
      final sarahGlucoseFilter = await vitalsRepository.getFilteredVitals(
        patientId: 10,
        vitalType: 'glucose',
      );
      expect(sarahGlucoseFilter.length, equals(1));
      expect(sarahGlucoseFilter.first.glucoseValue, equals(98.0));

      // Delete v2
      final glucoseRecord = sarahVitals.firstWhere((v) => v.glucoseValue == 98.0);
      await vitalsRepository.deleteVitalRecord(glucoseRecord.id, glucoseRecord.remoteId);

      final sarahVitalsAfterDelete = await vitalsRepository.getVitals(10);
      expect(sarahVitalsAfterDelete.length, equals(1));
      expect(sarahVitalsAfterDelete.first.glucoseValue, isNull);
    });

    test('Flow 3: AI Assistant Grounding, Patient Context, and GenUI Navigation', () async {
      final p1 = PatientModel()
        ..id = 10
        ..name = 'Sarah Connor'
        ..gender = 'Female'
        ..medicalConditions = ['Hypertension']
        ..medications = ['Lisinopril 10mg'];
      await patientRepository.savePatient(p1);

      // Add 3 BP records for Sarah
      for (int i = 0; i < 3; i++) {
        await vitalsRepository.saveVitalRecord(
          VitalRecord()
            ..patientId = 10
            ..dateTime = DateTime.now().subtract(Duration(days: i + 1))
            ..systolic = 126.0 + i
            ..diastolic = 80.0 + i
            ..pulseRate = 72.0,
        );
      }

      // Build HealthContext for Sarah
      final contextSarah = await healthContextService.buildHealthContext(10);
      expect(contextSarah.patientName, equals('Sarah Connor'));
      expect(contextSarah.hasBpData, isTrue);
      expect(contextSarah.bpSystolicTrend.totalReadings, equals(3));

      // Ask AI for BP Trend
      final response = await aiService.askAssistant(
        "Show me how my blood pressure has changed this month",
        healthContext: contextSarah,
      );

      // Verify grounded response
      expect(response, contains('Sarah Connor'));
      expect(response, contains('trend_chart'));
      expect(response, contains('/charts'));

      // Parse GenUI components
      final components = GenUiParser.parseComponents(response);
      expect(components.isNotEmpty, isTrue);
      expect(components.any((c) => c is GenUiTrendChartModel), isTrue);

      final actionBtn = components.firstWhere((c) => c is GenUiActionButtonModel) as GenUiActionButtonModel;
      expect(actionBtn.verifiedRoute, equals(GenUiValidRoutes.charts));
    });

    test('Flow 4: Reminders CRUD, Patient Isolation, and Notification Toggle', () async {
      final r1 = ReminderModel(
        id: 'rem_1',
        patientId: 10,
        title: 'Take Lisinopril 10mg',
        time: '08:00 AM',
        hour: 8,
        minute: 0,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      final r2 = ReminderModel(
        id: 'rem_2',
        patientId: 20,
        title: 'Check Blood Sugar',
        time: '12:00 PM',
        hour: 12,
        minute: 0,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      await reminderRepository.addReminder(r1);
      await reminderRepository.addReminder(r2);

      // Sarah's reminders
      final sarahReminders = await reminderRepository.getReminders(10);
      expect(sarahReminders.length, equals(1));
      expect(sarahReminders.first.title, equals('Take Lisinopril 10mg'));

      // John's reminders
      final johnReminders = await reminderRepository.getReminders(20);
      expect(johnReminders.length, equals(1));
      expect(johnReminders.first.title, equals('Check Blood Sugar'));

      // Toggle enabled
      final updatedR1 = r1.copyWith(isEnabled: false);
      await reminderRepository.updateReminder(updatedR1);

      final sarahRemindersUpdated = await reminderRepository.getReminders(10);
      expect(sarahRemindersUpdated.first.isEnabled, isFalse);

      // Delete reminder
      await reminderRepository.deleteReminder(r1.id, 10);
      final sarahRemindersAfterDelete = await reminderRepository.getReminders(10);
      expect(sarahRemindersAfterDelete.isEmpty, isTrue);
    });

    test('Flow 5: Settings State Persistence & Unit Preferences', () async {
      expect(settingsBloc.state.themeMode, equals(ThemeMode.system));
      expect(settingsBloc.state.tempUnit, equals('C'));
      expect(settingsBloc.state.glucoseUnit, equals('mg/dL'));

      // Change Theme
      settingsBloc.add(const ThemeChanged(themeMode: ThemeMode.dark, isHighContrast: false));
      await pumpEventQueue();
      expect(settingsBloc.state.themeMode, equals(ThemeMode.dark));
      expect(settingsBloc.state.isHighContrast, isFalse);

      // Change Temperature Unit
      settingsBloc.add(const TemperatureUnitChanged('F'));
      await pumpEventQueue();
      expect(settingsBloc.state.tempUnit, equals('F'));

      // Change Glucose Unit
      settingsBloc.add(const GlucoseUnitChanged('mmol/L'));
      await pumpEventQueue();
      expect(settingsBloc.state.glucoseUnit, equals('mmol/L'));

      // Change Weight Unit
      settingsBloc.add(const WeightUnitChanged('lbs'));
      await pumpEventQueue();
      expect(settingsBloc.state.weightUnit, equals('lbs'));

      // High Contrast
      settingsBloc.add(const ThemeChanged(themeMode: ThemeMode.dark, isHighContrast: true));
      await pumpEventQueue();
      expect(settingsBloc.state.isHighContrast, isTrue);

      // AI Consent
      settingsBloc.add(const AiConsentToggled(true));
      await pumpEventQueue();
      expect(settingsBloc.state.aiConsent, isTrue);

      // API Key
      settingsBloc.add(const ApiKeyUpdated('custom_gemini_test_key'));
      await pumpEventQueue();
      expect(settingsBloc.state.apiKey, equals('custom_gemini_test_key'));
    });

    test('Flow 6: SyncEngine Last-Write-Wins and Conflict Resolution', () {
      final syncEngine = SyncEngine();

      final localNewer = LocalRecord(
        id: 'vital_001',
        content: 'Systolic 122',
        updatedAt: DateTime(2026, 8, 10, 10, 30),
      );
      final remoteOlder = RemoteRecord(
        id: 'vital_001',
        content: 'Systolic 128',
        updatedAt: DateTime(2026, 8, 10, 9, 30),
      );

      final winner1 = syncEngine.resolveConflict(localNewer, remoteOlder);
      expect(winner1, isA<LocalRecord>());
      expect((winner1 as LocalRecord).content, equals('Systolic 122'));

      final localOlder = LocalRecord(
        id: 'vital_002',
        content: 'Glucose 100',
        updatedAt: DateTime(2026, 8, 10, 9, 0),
      );
      final remoteNewer = RemoteRecord(
        id: 'vital_002',
        content: 'Glucose 105',
        updatedAt: DateTime(2026, 8, 10, 11, 0),
      );

      final winner2 = syncEngine.resolveConflict(localOlder, remoteNewer);
      expect(winner2, isA<RemoteRecord>());
      expect((winner2 as RemoteRecord).content, equals('Glucose 105'));
    });
  });
}
