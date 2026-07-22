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

/// Settings screen for configuring user preferences, language, styling accessibility, and API keys.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
              // 0. Active Profile Context Header
              _buildProfileHeader(context),

              // 1. Theme Configuration Section
              _buildSectionTitle(theme, 'Theme & Accessibility'),
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.color_filter,
                        iconBg: const Color(0xFF8A3FFC), // Violet
                        title: 'Dark Mode Preference',
                        subtitle: _getThemeModeLabel(state.themeMode),
                        onTap: () => _showThemeSelectionDialog(context, state),
                      ),
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.eye,
                        iconBg: const Color(0xFF0F62FE), // Blue
                        title: 'High Contrast Text/Borders',
                        subtitle: 'Enhance visibility controls',
                        isLast: true,
                        trailing: CupertinoSwitch(
                          value: state.isHighContrast,
                          activeTrackColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            context.read<SettingsBloc>().add(ThemeChanged(
                                  themeMode: state.themeMode,
                                  isHighContrast: val,
                                ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Unit Preferences Section
              _buildSectionTitle(theme, 'Measurement Units'),
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.thermometer,
                        iconBg: const Color(0xFFFF5B4E), // Orange-Red
                        title: 'Temperature Unit',
                        subtitle: state.tempUnit == 'C'
                            ? 'Celsius (°C)'
                            : 'Fahrenheit (°F)',
                        onTap: () => _toggleTempUnit(context, state),
                      ),
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.drop,
                        iconBg: const Color(0xFF008A5E), // Teal-Green
                        title: 'Blood Glucose Unit',
                        subtitle: state.glucoseUnit,
                        onTap: () => _toggleGlucoseUnit(context, state),
                      ),
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.arrow_down_to_line_alt,
                        iconBg: const Color(0xFF0F8CFF), // Sky Blue
                        title: 'Weight Unit',
                        subtitle: state.weightUnit,
                        isLast: true,
                        onTap: () => _toggleWeightUnit(context, state),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. AI Integrations Section
              _buildSectionTitle(theme, 'AI Integration'),
              Card(
                margin: const EdgeInsets.only(bottom: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: CupertinoIcons.sparkles,
                        iconBg: const Color(0xFFFFB300), // Gold-Amber
                        title: 'Enable AI Insights',
                        subtitle: 'Processes vitals history context',
                        isLast: true,
                        trailing: CupertinoSwitch(
                          value: state.aiConsent,
                          activeTrackColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            context
                                .read<SettingsBloc>()
                                .add(AiConsentToggled(val));
                            locator<AiService>().setConsent(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Logout Session
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutPressed());
                    context.go('/login');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_right,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out Session',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, state) {
        final patientName =
            (state is PatientLoadSuccess && state.activePatient != null)
                ? state.activePatient!.name
                : 'No Profile Selected';
        final patientAge =
            (state is PatientLoadSuccess && state.activePatient != null)
                ? 'Born ${state.activePatient!.dateOfBirth.toIso8601String().split('T')[0]}'
                : 'Switch to a profile context';
        final initials =
            patientName.isNotEmpty ? patientName[0].toUpperCase() : '?';

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientAge,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_2_circlepath,
                    color: Colors.white),
                tooltip: 'Switch Patient Profile',
                onPressed: () => context.go('/patients'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 10.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                )
              : null,
          trailing: trailing ??
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: Colors.grey,
              ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
      ],
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'Follow System';
    }
  }

  void _showThemeSelectionDialog(BuildContext context, SettingsState state) {
    showDialog(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Select Display Mode'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(ThemeChanged(
                    themeMode: ThemeMode.light,
                    isHighContrast: state.isHighContrast,
                  ));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Light Mode'),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(ThemeChanged(
                    themeMode: ThemeMode.dark,
                    isHighContrast: state.isHighContrast,
                  ));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Dark Mode'),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.read<SettingsBloc>().add(ThemeChanged(
                    themeMode: ThemeMode.system,
                    isHighContrast: state.isHighContrast,
                  ));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Follow System'),
          ),
        ],
      ),
    );
  }

  void _toggleTempUnit(BuildContext context, SettingsState state) {
    final next = state.tempUnit == 'C' ? 'F' : 'C';
    context.read<SettingsBloc>().add(TemperatureUnitChanged(next));
  }

  void _toggleGlucoseUnit(BuildContext context, SettingsState state) {
    final next = state.glucoseUnit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
    context.read<SettingsBloc>().add(GlucoseUnitChanged(next));
  }

  void _toggleWeightUnit(BuildContext context, SettingsState state) {
    final next = state.weightUnit == 'kg' ? 'lbs' : 'kg';
    context.read<SettingsBloc>().add(WeightUnitChanged(next));
  }
}
