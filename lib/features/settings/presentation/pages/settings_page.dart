import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your VitalAI session?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
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
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // 1. Sleek Minimal Profile Pill
              BlocBuilder<PatientBloc, PatientState>(
                builder: (context, patientState) {
                  final active = patientState is PatientLoadSuccess
                      ? patientState.activePatient
                      : null;

                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: AppRadius.xl,
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            active != null && active.name.isNotEmpty
                                ? active.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active != null ? active.name : 'No Active Patient',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                active != null
                                    ? '${active.gender} • ${active.height.toInt()} cm • ${active.weight.toInt()} kg'
                                    : 'Tap switch to choose profile',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/patients'),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                          ),
                          child: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. Appearance Section
              _buildSectionTitle('APPEARANCE'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: AppRadius.xl,
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<ThemeMode>(
                        groupValue: state.themeMode,
                        children: const {
                          ThemeMode.light: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.light_mode_rounded, size: 15),
                                SizedBox(width: 5),
                                Text('Light', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          ThemeMode.dark: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.dark_mode_rounded, size: 15),
                                SizedBox(width: 5),
                                Text('Dark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          ThemeMode.system: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.settings_suggest_rounded, size: 15),
                                SizedBox(width: 5),
                                Text('System', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            context.read<SettingsBloc>().add(
                                  ThemeChanged(
                                    themeMode: val,
                                    isHighContrast: state.isHighContrast,
                                  ),
                                );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 18),
                    _buildSwitchTile(
                      icon: Icons.contrast_rounded,
                      iconColor: const Color(0xFF0F62FE),
                      title: 'High Contrast',
                      subtitle: 'Sharpen borders and outlines',
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
                  ],
                ),
              ),

              // 3. Measurement Units (Minimal Inline Selectors)
              _buildSectionTitle('MEASUREMENT UNITS'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: AppRadius.xl,
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    _buildUnitRow(
                      icon: CupertinoIcons.drop,
                      color: AppColors.glucoseVital,
                      label: 'Blood Glucose',
                      currentValue: state.glucoseUnit,
                      segments: const {
                        'mg/dL': Text('mg/dL', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        'mmol/L': Text('mmol/L', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      },
                      onChanged: (val) => context.read<SettingsBloc>().add(GlucoseUnitChanged(val)),
                    ),
                    const Divider(height: 16),
                    _buildUnitRow(
                      icon: CupertinoIcons.thermometer,
                      color: AppColors.tempVital,
                      label: 'Temperature',
                      currentValue: state.tempUnit,
                      segments: const {
                        'C': Text('°C', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        'F': Text('°F', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      },
                      onChanged: (val) => context.read<SettingsBloc>().add(TemperatureUnitChanged(val)),
                    ),
                    const Divider(height: 16),
                    _buildUnitRow(
                      icon: CupertinoIcons.speedometer,
                      color: AppColors.weightVital,
                      label: 'Body Weight',
                      currentValue: state.weightUnit,
                      segments: const {
                        'kg': Text('kg', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        'lbs': Text('lbs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      },
                      onChanged: (val) => context.read<SettingsBloc>().add(WeightUnitChanged(val)),
                    ),
                  ],
                ),
              ),

              // 4. AI & Privacy
              _buildSectionTitle('AI & PRIVACY'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: AppRadius.xl,
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: CupertinoIcons.sparkles,
                      iconColor: AppColors.tertiary,
                      title: 'Gemini AI Engine',
                      subtitle: state.apiKey.isNotEmpty ? 'Custom Key Active' : 'Gemini 2.5 Flash',
                      trailing: TextButton(
                        onPressed: () => _openApiKeyDialog(context, state.apiKey),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.tertiary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('API Key', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.tertiary)),
                      ),
                    ),
                    const Divider(height: 16),
                    _buildSwitchTile(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.secondary,
                      title: 'AI Health Sharing',
                      subtitle: 'Allow personalized vitals analysis',
                      value: state.aiConsent,
                      onChanged: (val) => context.read<SettingsBloc>().add(AiConsentToggled(val)),
                    ),
                  ],
                ),
              ),

              // 5. Portals & Tour
              _buildSectionTitle('GENERAL'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: AppRadius.xl,
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: CupertinoIcons.person_2_fill,
                      iconColor: AppColors.primary,
                      title: 'Caregiver Portal',
                      subtitle: 'Family access and sync',
                      onTap: () => context.go('/caregiver'),
                    ),
                    const Divider(height: 16),
                    _buildLinkTile(
                      icon: CupertinoIcons.compass_fill,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Onboarding Tour',
                      subtitle: 'Replay app introduction',
                      onTap: () => context.go('/onboarding'),
                    ),
                  ],
                ),
              ),

              // 6. Sign Out
              AppCard(
                onTap: () => _confirmSignOut(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: AppRadius.xl,
                margin: const EdgeInsets.only(bottom: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildUnitRow({
    required IconData icon,
    required Color color,
    required String label,
    required String currentValue,
    required Map<String, Widget> segments,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ],
        ),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: currentValue,
          children: segments,
          onValueChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
