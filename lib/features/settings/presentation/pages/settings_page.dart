import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
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
          if (locator.isRegistered<AiService>()) {
            locator<AiService>().updateApiKey(newKey);
          }
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
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
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutPressed());
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker(BuildContext context, SettingsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Health Measurement Units',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Temperature Unit'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'C', label: Text('°C')),
                    ButtonSegment(value: 'F', label: Text('°F')),
                  ],
                  selected: {state.tempUnit},
                  onSelectionChanged: (val) {
                    context.read<SettingsBloc>().add(TemperatureUnitChanged(val.first));
                  },
                ),
              ),
              ListTile(
                title: const Text('Blood Glucose Unit'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'mg/dL', label: Text('mg/dL')),
                    ButtonSegment(value: 'mmol/L', label: Text('mmol/L')),
                  ],
                  selected: {state.glucoseUnit},
                  onSelectionChanged: (val) {
                    context.read<SettingsBloc>().add(GlucoseUnitChanged(val.first));
                  },
                ),
              ),
              ListTile(
                title: const Text('Weight Unit'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('kg')),
                    ButtonSegment(value: 'lbs', label: Text('lbs')),
                  ],
                  selected: {state.weightUnit},
                  onSelectionChanged: (val) {
                    context.read<SettingsBloc>().add(WeightUnitChanged(val.first));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<PatientBloc, PatientState>(
          builder: (context, patientState) {
            final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;
            final patientName = activePatient?.name ?? 'Alex Thorne';
            final age = activePatient != null
                ? (DateTime.now().year - activePatient.dateOfBirth.year)
                : 32;
            final bloodType = (activePatient?.notes != null && activePatient!.notes!.isNotEmpty)
                ? activePatient.notes!
                : 'O+';
            final heightStr = activePatient != null ? '${activePatient.height.toInt()} cm' : '182 cm';
            final conditions = (activePatient != null && activePatient.medicalConditions.isNotEmpty)
                ? activePatient.medicalConditions.join(', ')
                : 'Hypertension';
            final allergies = (activePatient != null && activePatient.allergies.isNotEmpty)
                ? activePatient.allergies.join(', ')
                : 'Penicillin (Severe)';

            return Scaffold(
              backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              appBar: AppTopBar(
                title: 'Profile',
                initials: patientName,
                trailing: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Sign Out',
                  onPressed: () => _confirmSignOut(context),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero Profile Card
                      _buildHeroProfileCard(
                        context,
                        name: patientName,
                        id: '#9842-AX',
                        age: '$age',
                        bloodType: bloodType,
                        height: heightStr,
                      ),
                      const SizedBox(height: 24),

                      // 2. HEALTH DATA Section
                      _buildSectionHeader('HEALTH DATA', isDark),
                      const SizedBox(height: 10),
                      _buildSettingsGroup(
                        context,
                        children: [
                          _buildProfileRow(
                            context,
                            icon: Icons.description_outlined,
                            iconBg: const Color(0xFFEBF5FF),
                            iconColor: const Color(0xFF0062E0),
                            title: 'Medical Records',
                            subtitle: 'Visit history, lab results, imaging',
                            onTap: () => context.push('/history'),
                          ),
                          _buildDivider(isDark),
                          _buildProfileRow(
                            context,
                            icon: Icons.medication_outlined,
                            iconBg: const Color(0xFFEEF2FF),
                            iconColor: const Color(0xFF6366F1),
                            title: 'Medications',
                            subtitle: '2 Active prescriptions ($conditions)',
                            onTap: () => context.push('/reminders'),
                          ),
                          _buildDivider(isDark),
                          _buildProfileRow(
                            context,
                            icon: Icons.warning_amber_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            title: 'Allergies',
                            subtitle: allergies,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. ACCOUNT Section
                      _buildSectionHeader('ACCOUNT', isDark),
                      const SizedBox(height: 10),
                      _buildSettingsGroup(
                        context,
                        children: [
                          _buildProfileRow(
                            context,
                            icon: Icons.people_outline_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            title: 'Switch Profile / Family',
                            subtitle: 'Manage multi-patient profiles',
                            onTap: () => context.push('/patients'),
                          ),
                          _buildDivider(isDark),
                          _buildProfileRow(
                            context,
                            icon: Icons.key_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            title: 'Gemini AI API Key',
                            subtitle: settingsState.apiKey.isNotEmpty ? '✓ Live Gemini AI Connected' : 'Configure API Key',
                            onTap: () => _openApiKeyDialog(context, settingsState.apiKey),
                          ),
                          _buildDivider(isDark),
                          _buildProfileRow(
                            context,
                            icon: Icons.tune_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconColor: const Color(0xFF475569),
                            title: 'Units & Measurements',
                            subtitle: '${settingsState.tempUnit}° / ${settingsState.glucoseUnit} / ${settingsState.weightUnit}',
                            onTap: () => _showUnitPicker(context, settingsState),
                          ),
                          _buildDivider(isDark),
                          _buildProfileRow(
                            context,
                            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconColor: const Color(0xFF475569),
                            title: 'Dark Theme',
                            subtitle: isDark ? 'Dark theme active' : 'Light theme active',
                            trailing: Switch(
                              value: isDark,
                              activeThumbColor: const Color(0xFF0062E0),
                              onChanged: (val) {
                                context.read<SettingsBloc>().add(
                                      ThemeChanged(
                                        themeMode: val ? ThemeMode.dark : ThemeMode.light,
                                        isHighContrast: settingsState.isHighContrast,
                                      ),
                                    );
                              },
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // 4. Footer Pill (HIPAA Compliant)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Data encrypted & HIPAA Compliant',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildHeroProfileCard(
    BuildContext context, {
    required String name,
    required String id,
    required String age,
    required String bloodType,
    required String height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Green Checkmark
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFEBF5FF),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0062E0),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: $id',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0062E0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 3-Column Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statItem('Age', age, '', isDark),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _statItem('Blood', bloodType, '', isDark, valueColor: const Color(0xFFEF4444)),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _statItem('Height', height, '', isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, bool isDark, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      indent: 58,
      endIndent: 16,
    );
  }
}
