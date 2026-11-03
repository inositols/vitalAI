import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/provider_profile.dart';

class ProfileHeaderCard extends StatelessWidget {
  final ProviderProfile profile;

  const ProfileHeaderCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTypography.titleLarge(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.role,
                  style: AppTypography.bodyMedium(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.facility,
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
