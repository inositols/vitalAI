import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_event.dart';
import '../database/db_service.dart';
import '../notifications/notification_service.dart';
import '../services/ai_service.dart';
import '../plugin/module_registry.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/patients/domain/repositories/patient_repository.dart';
import '../../features/patients/data/repositories/patient_repository_impl.dart';
import '../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

final GetIt locator = GetIt.instance;

/// Configure global dependency locator.
Future<void> setupLocator() async {
  // 1. Secure Storage
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  locator.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  // 2. Local Database Service
  final dbService = DbService(locator());
  locator.registerSingleton<DbService>(dbService);

  // 3. Notification Manager
  final notificationService = NotificationService();
  await notificationService.init();
  locator.registerSingleton<NotificationService>(notificationService);

  // 4. Settings Block (pre-loaded before other repositories)
  final settingsBloc = SettingsBloc(secureStorage: locator());
  settingsBloc.add(SettingsLoadRequested());
  // Wait brief moment for initial loading
  await settingsBloc.stream
      .firstWhere(
        (state) => state.apiKey.isNotEmpty || state.tempUnit.isNotEmpty,
      )
      .timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => settingsBloc.state,
      );
  locator.registerSingleton<SettingsBloc>(settingsBloc);

  // 5. AI Gemini Client
  final apiKey = settingsBloc.state.apiKey;
  final aiService = AiService(apiKey.isNotEmpty ? apiKey : null);
  aiService.setConsent(settingsBloc.state.aiConsent);
  locator.registerSingleton<AiService>(aiService);

  // 6. Authentication Core
  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  locator.registerFactory(() => AuthBloc(authRepository: locator()));

  // 7. Multi-Profile Patient Core
  locator.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryImpl(locator()),
  );
  locator.registerFactory(() => PatientBloc(patientRepository: locator()));

  // 8. Register Dynamic Plugin-Based Modules Dependencies
  ModuleRegistry.instance.registerModuleDependencies(locator);

  // 9. Initialize Database (After registering all module schemas)
  await dbService.init();
}
