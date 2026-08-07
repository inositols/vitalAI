import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_card.dart';
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

  void _confirmSignOut(BuildContext context) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Sign Out?'),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your VitalAI account?',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutPressed());
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                AppBrandLogo(
                  size: 28,
                  iconSize: 14,
                ),
                SizedBox(width: 8),
                Text('Settings & Preferences'),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            children: [
              // Patient Profile Card Context
              BlocBuilder<PatientBloc, PatientState>(
                builder: (context, patientState) {
                  final active = patientState is PatientLoadSuccess
                      ? patientState.activePatient
                      : null;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: Center(
                          child: Text(
                            active != null && active.name.isNotEmpty
                                ? active.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        active != null ? active.name : 'No Active Patient',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      subtitle: Text(
                        active != null
                            ? '${active.gender} • ${active.height.toInt()} cm • ${active.weight.toInt()} kg'
                            : 'Tap to select active profile',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      trailing: const Icon(Icons.swap_horiz_rounded, size: 22, color: AppColors.primary),
                      onTap: () => context.go('/patients'),
                    ),
                  );
                },
              ),

              // Caregiver & Sharing Section
              SettingsSection(
                title: 'Sharing & Caregivers',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.person_2_fill,
                    iconBg: AppColors.primary,
                    title: 'Caregiver Portal',
                    subtitle: 'Manage family access & remote emergency sharing',
                    onTap: () => context.go('/caregiver'),
                  ),
                ],
              ),

              // Theme & Accessibility
              SettingsSection(
                title: 'Theme & Accessibility',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.color_filter,
                    iconBg: const Color(0xFF8A3FFC),
                    title: 'Appearance Mode',
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
                    subtitle: 'Enhance text legibility and outline boundaries',
                    trailing: CupertinoSwitch(
                      value: state.isHighContrast,
                      activeTrackColor: AppColors.primary,
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

              // App Experience
              SettingsSection(
                title: 'App Experience',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.compass_fill,
                    iconBg: AppColors.tertiary,
                    title: 'Replay Onboarding Tour',
                    subtitle: 'View intro slides & feature walkthrough',
                    onTap: () => context.go('/onboarding'),
                  ),
                ],
              ),

              // Units Configuration
              SettingsSection(
                title: 'Measurement Units',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.drop,
                    iconBg: AppColors.glucoseVital,
                    title: 'Blood Glucose Unit',
                    subtitle: state.glucoseUnit,
                    onTap: () {
                      final next = state.glucoseUnit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
                      context.read<SettingsBloc>().add(GlucoseUnitChanged(next));
                    },
                  ),
                  SettingTileItem(
                    icon: CupertinoIcons.thermometer,
                    iconBg: AppColors.tempVital,
                    title: 'Temperature Unit',
                    subtitle: '°${state.tempUnit}',
                    onTap: () {
                      final next = state.tempUnit == 'C' ? 'F' : 'C';
                      context.read<SettingsBloc>().add(TemperatureUnitChanged(next));
                    },
                  ),
                  SettingTileItem(
                    icon: CupertinoIcons.speedometer,
                    iconBg: AppColors.weightVital,
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
                title: 'AI Companion & Engine',
                children: [
                  SettingTileItem(
                    icon: CupertinoIcons.sparkles,
                    iconBg: AppColors.tertiary,
                    title: 'Gemini API Key',
                    subtitle: state.apiKey.isNotEmpty ? 'Custom Key Configured' : 'Default Key Active',
                    onTap: () => _openApiKeyDialog(context, state.apiKey),
                  ),
                ],
              ),

              // Account & Log Out
              SettingsSection(
                title: 'Account & Security',
                children: [
                  SettingTileItem(
                    icon: Icons.logout_rounded,
                    iconBg: AppColors.error,
                    title: 'Sign Out',
                    subtitle: 'Log out of current session',
                    onTap: () => _confirmSignOut(context),
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
