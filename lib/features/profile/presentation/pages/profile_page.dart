import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/voice_vitals_top_bar.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_header_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const VoiceVitalsTopBar(),
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final profile = state.profile;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  'Provider Profile',
                  style: AppTypography.headlineLarge(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clinical credentials & preferences',
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ProfileHeaderCard(profile: profile),
                const SizedBox(height: 24),
                _buildSectionHeader('Clinical Details', isDark),
                const SizedBox(height: 12),
                _buildInfoTile('License Number', profile.licenseNumber, isDark),
                const SizedBox(height: 8),
                _buildInfoTile('Specialty', profile.specialty, isDark),
                const SizedBox(height: 8),
                _buildInfoTile('Email', profile.email, isDark),
                const SizedBox(height: 24),
                _buildSectionHeader('Preferences', isDark),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Voice Response (TTS)',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  subtitle: Text(
                    'Speak responses after actions execute',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  value: profile.voiceFeedbackEnabled,
                  onChanged: (_) => context.read<ProfileCubit>().toggleVoiceFeedback(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.secondary,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
