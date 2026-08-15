import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';
import 'features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/patients/presentation/bloc/patient_bloc.dart';
import 'features/patients/presentation/bloc/patient_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/vitals/presentation/bloc/vitals_bloc.dart';
import 'features/reminders/presentation/bloc/reminders_bloc.dart';

class VitalApp extends StatelessWidget {
  const VitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: locator<SettingsBloc>()),
        BlocProvider<AuthBloc>(
          create: (context) => locator<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<PatientBloc>(
          create: (context) => locator<PatientBloc>()..add(PatientListRequested()),
        ),
        BlocProvider<VitalsBloc>(create: (context) => locator<VitalsBloc>()),
        BlocProvider<AiAssistantBloc>(
          create: (context) => locator<AiAssistantBloc>(),
        ),
        BlocProvider<RemindersBloc>(
          create: (context) => locator<RemindersBloc>(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          final lightTheme = settings.isHighContrast
              ? AppTheme.highContrastLightTheme
              : AppTheme.lightTheme;
          final darkTheme = settings.isHighContrast
              ? AppTheme.highContrastDarkTheme
              : AppTheme.darkTheme;

          return MaterialApp.router(
            title: 'VitalAI Health',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
