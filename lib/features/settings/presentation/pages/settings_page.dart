import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/ai_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'package:vitalai/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:vitalai/features/patients/presentation/bloc/patient_state.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _openApiKeyDialog(BuildContext context, String currentKey) {
    showDialog(
      context: context,
      builder: (ctx) => ApiKeyDialog(
        currentApiKey: currentKey,
        onSave: (newKey) {
          context.read<SettingsBloc>().add(ApiKeyUpdated(newKey));
          locator<AiService>().updateApiKey(newKey);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
              // Patient Profile Card Context
              BlocBuilder<PatientBloc, PatientState>(
                builder: (context, patientState) {
                  final active = patientState is PatientLoadSuccess
                      ? patientState.activePatient
                      : null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          active != null && active.name.isNotEmpty
                              ? active.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        active != null ? active.name : 'No Active Patient',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        active != null
                            ? '${active.gender} • ${active.height.toInt()} cm'
                            : 'Select patient profile',
                      ),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: () => context.go('/patients'),
                    ),
                  );
                },
              ),

              // Theme & Accessibility
              SettingsSection(
                title: 'Theme & Accessibility',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.color_filter,
                    iconBg: const Color(0xFF8A3FFC),
                    title: 'Dark Mode Preference',
                    subtitle: state.themeMode == ThemeMode.dark
                        ? 'Dark Mode'
                        : state.themeMode == ThemeMode.light
                            ? 'Light Mode'
                            : 'System Default',
                    onTap: () {
                      final next = state.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      context.read<SettingsBloc>().add(
                            ThemeChanged(
                              themeMode: next,
                              isHighContrast: state.isHighContrast,
                            ),
                          );
                    },
                  ),
                  SettingTileItem(
                    icon: CupertinoIcons.eye,
                    iconBg: const Color(0xFF0F62FE),
                    title: 'High Contrast Mode',
                    subtitle: 'Enhance text contrast and boundaries',
                    trailing: CupertinoSwitch(
                      value: state.isHighContrast,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                              ThemeChanged(
                                themeMode: state.themeMode,
                                isHighContrast: val,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),

              // Units Configuration
              SettingsSection(
                title: 'Measurement Units',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.drop,
                    iconBg: Colors.orange,
                    title: 'Blood Glucose Unit',
                    subtitle: state.glucoseUnit,
                    onTap: () {
                      final next = state.glucoseUnit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
                      context.read<SettingsBloc>().add(GlucoseUnitChanged(next));
                    },
                  ),
                  SettingTileItem(
                    icon: CupertinoIcons.thermometer,
                    iconBg: Colors.redAccent,
                    title: 'Temperature Unit',
                    subtitle: '°${state.tempUnit}',
                    onTap: () {
                      final next = state.tempUnit == 'C' ? 'F' : 'C';
                      context.read<SettingsBloc>().add(TemperatureUnitChanged(next));
                    },
                  ),
                  SettingTileItem(
                    icon: CupertinoIcons.speedometer,
                    iconBg: Colors.green,
                    title: 'Weight Unit',
                    subtitle: state.weightUnit,
                    onTap: () {
                      final next = state.weightUnit == 'kg' ? 'lbs' : 'kg';
                      context.read<SettingsBloc>().add(WeightUnitChanged(next));
                    },
                  ),
                ],
              ),

              // AI Engine & API Keys
              SettingsSection(
                title: 'AI Companion & API Key',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.sparkles,
                    iconBg: Colors.indigo,
                    title: 'Gemini API Key',
                    subtitle: state.apiKey.isNotEmpty ? 'Custom Key Set' : 'Default Key',
                    onTap: () => _openApiKeyDialog(context, state.apiKey),
                  ),
                ],
              ),

              // Account & Log Out
              SettingsSection(
                title: 'Account & System',
                children: [
                  SettingTileItem(
                    icon: Icons.logout,
                    iconBg: Colors.red,
                    title: 'Sign Out',
                    subtitle: 'Log out of VitalAI account',
                    onTap: () {
                      context.read<AuthBloc>().add(AuthSignOutPressed());
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
