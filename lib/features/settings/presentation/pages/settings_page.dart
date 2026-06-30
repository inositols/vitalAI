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

/// Settings screen for configuring user preferences, language, styling accessibility, and API keys.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsBloc>().state;
    _apiKeyController = TextEditingController(text: settingsState.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Theme Configuration
              _buildSectionTitle(theme, 'Theme & Accessibility'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Dark Mode Preference'),
                      subtitle: Text(_getThemeModeLabel(state.themeMode)),
                      leading: const Icon(Icons.palette_outlined),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => _showThemeSelectionDialog(context, state),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('High Contrast Text/Borders'),
                      subtitle: const Text('Enhance visibility controls'),
                      value: state.isHighContrast,
                      secondary: const Icon(Icons.accessibility_new_outlined),
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ThemeChanged(
                              themeMode: state.themeMode,
                              isHighContrast: val,
                            ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Unit Preferences
              _buildSectionTitle(theme, 'Measurement Units'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Temperature Unit'),
                      trailing: Text(state.tempUnit == 'C' ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                      leading: const Icon(Icons.thermostat_outlined),
                      onTap: () => _toggleTempUnit(context, state),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Blood Glucose Unit'),
                      trailing: Text(state.glucoseUnit),
                      leading: const Icon(Icons.opacity),
                      onTap: () => _toggleGlucoseUnit(context, state),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Weight Unit'),
                      trailing: Text(state.weightUnit),
                      leading: const Icon(Icons.scale_outlined),
                      onTap: () => _toggleWeightUnit(context, state),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. AI Integrations
              _buildSectionTitle(theme, 'AI Integration'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable AI Insights'),
                        subtitle: const Text('Processes vitals history context'),
                        value: state.aiConsent,
                        secondary: const Icon(Icons.auto_awesome_outlined),
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(AiConsentToggled(val));
                          locator<AiService>().setConsent(val);
                        },
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Gemini API Key',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _apiKeyController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter API key here',
                                      prefixIcon: Icon(Icons.vpn_key_outlined),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    final key = _apiKeyController.text.trim();
                                    context.read<SettingsBloc>().add(ApiKeyUpdated(key));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('API Key Updated.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Logout / Session Exit
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Log Out Session'),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthSignOutPressed());
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
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
