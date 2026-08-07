import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalai/core/database/db_service.dart';
import 'package:vitalai/core/services/ai_service.dart';
import 'package:vitalai/features/ai_assistant/data/models/chat_conversation.dart';
import 'package:vitalai/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:vitalai/features/ai_assistant/domain/services/health_context_service.dart';
import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/domain/repositories/patient_repository.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/vitals/domain/repositories/vitals_repository.dart';

class MockPatientRepository extends Mock implements PatientRepository {}
class MockVitalsRepository extends Mock implements VitalsRepository {}
class MockDbService extends Mock implements DbService {}

void main() {
  late MockPatientRepository mockPatientRepo;
  late MockVitalsRepository mockVitalsRepo;
  late HealthContextService contextService;

  setUp(() {
    mockPatientRepo = MockPatientRepository();
    mockVitalsRepo = MockVitalsRepository();
    contextService = HealthContextService(
      patientRepository: mockPatientRepo,
      vitalsRepository: mockVitalsRepo,
    );
  });

  group('HealthContextService Tests', () {
    final testPatient = PatientModel()
      ..id = 1
      ..remoteId = 'p1'
      ..name = 'John Doe'
      ..gender = 'Male'
      ..dateOfBirth = DateTime(1985, 5, 20)
      ..height = 175
      ..weight = 70
      ..emergencyContact = '555-0199'
      ..medicalConditions = ['Hypertension']
      ..allergies = ['Penicillin']
      ..medications = ['Lisinopril 10mg']
      ..isSynced = true
      ..updatedAt = DateTime.now();

    final testVital1 = VitalRecord()
      ..id = 101
      ..remoteId = 'v1'
      ..patientId = 1
      ..dateTime = DateTime.now().subtract(const Duration(days: 5))
      ..systolic = 120
      ..diastolic = 80
      ..glucoseValue = 110
      ..pulseRate = 72
      ..oxygenSaturation = 98
      ..bodyTemperature = 36.6
      ..weight = 70
      ..bmi = 22.8
      ..note = 'Felt energetic'
      ..tags = ['morning']
      ..isSynced = true
      ..updatedAt = DateTime.now();

    final testVital2 = VitalRecord()
      ..id = 102
      ..remoteId = 'v2'
      ..patientId = 1
      ..dateTime = DateTime.now().subtract(const Duration(days: 1))
      ..systolic = 128
      ..diastolic = 84
      ..glucoseValue = 100
      ..pulseRate = 75
      ..oxygenSaturation = 97
      ..bodyTemperature = 36.8
      ..weight = 69.8
      ..bmi = 22.7
      ..note = 'After walking'
      ..tags = ['exercise']
      ..isSynced = true
      ..updatedAt = DateTime.now();

    test('buildHealthContext computes correct averages and trends', () async {
      when(() => mockPatientRepo.getPatients()).thenAnswer((_) async => [testPatient]);
      when(() => mockVitalsRepo.getVitals(1)).thenAnswer((_) async => [testVital1, testVital2]);

      final context = await contextService.buildHealthContext(1);

      expect(context.patientName, equals('John Doe'));
      expect(context.bpSystolicTrend.average, equals(124.0));
      expect(context.bpDiastolicTrend.average, equals(82.0));
      expect(context.glucoseTrend.average, equals(105.0));
      expect(context.hasBpData, isTrue);
      expect(context.hasGlucoseData, isTrue);
      expect(context.hasMedications, isTrue);
    });

    test('generateSmartSuggestions creates dynamic chips based on available data', () async {
      when(() => mockPatientRepo.getPatients()).thenAnswer((_) async => [testPatient]);
      when(() => mockVitalsRepo.getVitals(1)).thenAnswer((_) async => [testVital1, testVital2]);

      final context = await contextService.buildHealthContext(1);
      final suggestions = contextService.generateSmartSuggestions(context);

      expect(suggestions, contains('Analyse my blood pressure trend'));
      expect(suggestions, contains('Explain my glucose pattern'));
      expect(suggestions, contains('Review my medication adherence'));
      expect(suggestions, contains('Prepare questions for my doctor'));
    });
  });

  group('AiAssistantRepositoryImpl Tests', () {
    late MockDbService mockDb;
    late AiAssistantRepositoryImpl repo;

    setUp(() {
      mockDb = MockDbService();
      repo = AiAssistantRepositoryImpl(mockDb);
    });

    test('getConversations sorts conversations by updatedAt descending', () async {
      final conv1 = ChatConversation(
        id: 'c1',
        patientId: 1,
        title: 'Chat 1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final conv2 = ChatConversation(
        id: 'c2',
        patientId: 1,
        title: 'Chat 2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      when(() => mockDb.getConversations(1)).thenAnswer((_) async => [conv1, conv2]);

      final list = await repo.getConversations(1);

      expect(list.first.id, equals('c2'));
      expect(list.last.id, equals('c1'));
    });

    test('saveConversation adds or updates conversation in DbService', () async {
      final conv = ChatConversation(
        id: 'c1',
        patientId: 1,
        title: 'New Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockDb.getConversations(1)).thenAnswer((_) async => []);
      when(() => mockDb.saveConversations(1, any())).thenAnswer((_) async {});

      await repo.saveConversation(conv);

      verify(() => mockDb.saveConversations(1, any(that: isA<List<ChatConversation>>()))).called(1);
    });
  });

  group('AiService Offline Fallback Tests', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService('invalid_key');
    });

    test('askAssistant generates emergency alert for hypertensive crisis input', () async {
      final response = await aiService.askAssistant("My BP reading was 185/120");
      expect(response, contains('EMERGENCY'));
    });

    test('askAssistant offline fallback provides context-aware blood pressure response', () async {
      final response = await aiService.askAssistant("How has my blood pressure changed recently?");
      expect(response.toLowerCase(), contains('blood pressure'));
    });
  });
}
