import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../../core/database/db_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/clinical_data_seeder.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_event.dart';

/// Doctor Profile & Settings sheet accessible from the top-right avatar.
class DoctorProfileSheet extends StatefulWidget {
  const DoctorProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DoctorProfileSheet(),
    );
  }

  @override
  State<DoctorProfileSheet> createState() => _DoctorProfileSheetState();
}

class _DoctorProfileSheetState extends State<DoctorProfileSheet> {
  bool _voiceFeedbackEnabled = true;
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Provider Profile',
                    style: AppTypography.titleLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Doctor Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkContainer : AppColors.subtleTealSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.subtleTealBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'DA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Dr. Adeyemi',
                                style: AppTypography.titleMedium(
                                  color: isDark ? Colors.white : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'MD',
                                  style: AppTypography.labelSmall(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cardiology & Internal Medicine',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'adeyemi@voicevitals.health',
                            style: AppTypography.labelSmall(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Settings Section Header
              Text(
                'Clinical Settings & Preferences',
                style: AppTypography.labelMedium(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 10),

              // Voice Preferences Toggle
              _buildSettingTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Text-to-Speech Voice Responses',
                subtitle: 'Assistant reads aloud clinical summaries',
                trailing: Switch.adaptive(
                  value: _voiceFeedbackEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _voiceFeedbackEnabled = val);
                  },
                ),
              ),

              // Privacy & Security
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Local AES-256 encrypted database & clinical audit trail',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSuccessContainer,
                    ),
                  ),
                ),
              ),

              // Data Sync Status
              _buildSettingTile(
                icon: Icons.cloud_done_outlined,
                title: 'Data Sync Status',
                subtitle: 'All records stored securely with cloud backup ready',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Synced',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // About VoiceVitals
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About VoiceVitals',
                subtitle: 'Version 1.0.0 • Clinical AI Voice Assistant',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'VoiceVitals',
                    applicationVersion: '1.0.0 (Clinical Workspace)',
                    applicationIcon: const AppBrandLogo(size: 40),
                    children: const [
                      Text(
                        'VoiceVitals is a voice-first clinical assistant designed for healthcare providers to access patient records, review vitals, and draft documentation naturally.',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Reset Demo Clinical Data Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isResetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset Demo Clinical Records'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isResetting
                      ? null
                      : () async {
                          setState(() => _isResetting = true);
                          final patientBloc = context.read<PatientBloc>();
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final dbService = locator<DbService>();
                          await dbService.clearAll();
                          await ClinicalDataSeeder.seedDefaultClinicalData(dbService);
                          patientBloc.add(PatientListRequested());
                          if (mounted) {
                            setState(() => _isResetting = false);
                          }
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Demo clinical dataset reloaded successfully.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(height: 8),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(AuthSignOutPressed());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkContainer : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
