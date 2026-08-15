import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:vitalai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';
import '../database/db_service.dart';
import '../notifications/notification_service.dart';
import '../services/ai_service.dart';
import '../plugin/module_registry.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/patients/domain/repositories/patient_repository.dart';
import '../../features/patients/data/repositories/patient_repository_impl.dart';
import '../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/vitals/domain/repositories/vitals_repository.dart';
import '../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import '../../features/ai_assistant/domain/services/health_context_service.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/reminders/presentation/bloc/reminders_bloc.dart';

final GetIt locator = GetIt.instance;

/// Configure global dependency locator.
Future<void> setupLocator() async {
  // 1. Secure Storage
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  locator.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  // 2. Local Database Service
  final dbService = DbService(locator<FlutterSecureStorage>());
  locator.registerSingleton<DbService>(dbService);

  // 3. Notification Manager
  final notificationService = NotificationService();
  await notificationService.init();
  locator.registerSingleton<NotificationService>(notificationService);

  // 4. Preload Settings so frame 0 matches user's saved theme & units (Zero Flash)
  final themeStr = await secureStorage.read(key: 'theme_mode');
  final hcStr = await secureStorage.read(key: 'is_high_contrast');
  final tempUnit = await secureStorage.read(key: 'temp_unit') ?? 'C';
  final glucoseUnit = await secureStorage.read(key: 'glucose_unit') ?? 'mg/dL';
  final weightUnit = await secureStorage.read(key: 'weight_unit') ?? 'kg';
  final lang = await secureStorage.read(key: 'language_code') ?? 'en';
  final consentStr = await secureStorage.read(key: 'ai_consent');
  final apiKey = await secureStorage.read(key: 'api_key') ?? '';

  ThemeMode themeMode = ThemeMode.light;
  if (themeStr == 'dark') themeMode = ThemeMode.dark;
  if (themeStr == 'system') themeMode = ThemeMode.system;
  if (themeStr == 'light') themeMode = ThemeMode.light;

  final initialSettingsState = SettingsState(
    themeMode: themeMode,
    isHighContrast: hcStr == 'true',
    tempUnit: tempUnit,
    glucoseUnit: glucoseUnit,
    weightUnit: weightUnit,
    languageCode: lang,
    aiConsent: consentStr == 'true',
    apiKey: apiKey,
  );

  final settingsBloc = SettingsBloc(
    secureStorage: secureStorage,
    initialState: initialSettingsState,
  );
  locator.registerSingleton<SettingsBloc>(settingsBloc);

  // 5. AI Gemini Client
  const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  final initialKey = apiKey.isNotEmpty ? apiKey : geminiApiKey;
  final aiService = AiService(initialKey);
  locator.registerSingleton<AiService>(aiService);

  // 6. Authentication Core (Preload stored session for seamless startup)
  final authRepository = AuthRepositoryImpl(locator<FlutterSecureStorage>());
  await authRepository.init();
  locator.registerSingleton<AuthRepository>(authRepository);
  locator.registerFactory(
    () => AuthBloc(authRepository: locator<AuthRepository>()),
  );

  // 7. Multi-Profile Patient Core
  locator.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryImpl(locator<DbService>()),
  );
  locator.registerFactory(
    () => PatientBloc(patientRepository: locator<PatientRepository>()),
  );

  // 8. Register Dynamic Plugin-Based Modules Dependencies
  ModuleRegistry.instance.registerModuleDependencies(locator);

  // 9. AI Assistant Core
  locator.registerLazySingleton<HealthContextService>(
    () => HealthContextService(
      patientRepository: locator<PatientRepository>(),
      vitalsRepository: locator<VitalsRepository>(),
    ),
  );

  locator.registerLazySingleton<AiAssistantRepository>(
    () => AiAssistantRepositoryImpl(locator<DbService>()),
  );

  locator.registerFactory(
    () => AiAssistantBloc(
      repository: locator<AiAssistantRepository>(),
      contextService: locator<HealthContextService>(),
      aiService: locator<AiService>(),
    ),
  );

  // 10. Reminders Core
  locator.registerLazySingleton<ReminderRepository>(
    () => ReminderRepositoryImpl(
      dbService: locator<DbService>(),
      notificationService: locator<NotificationService>(),
    ),
  );

  locator.registerFactory(
    () => RemindersBloc(repository: locator<ReminderRepository>()),
  );

  // 11. Initialize Database
  await dbService.init();
}
