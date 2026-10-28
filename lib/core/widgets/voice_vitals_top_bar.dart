import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'app_brand_logo.dart';
import '../../features/settings/presentation/widgets/doctor_profile_sheet.dart';

/// Reusable top app bar for VoiceVitals screens matching the concept design.
class VoiceVitalsTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showAvatar;
  final String? titleOverride;
  final String? subtitleOverride;

  const VoiceVitalsTopBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.showAvatar = true,
    this.titleOverride,
    this.subtitleOverride,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left area: Back button or Logo + Title
            Row(
              children: [
                if (showBack) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    color: isDark ? Colors.white : AppColors.secondary,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                ],
                const AppBrandLogo(size: 28),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titleOverride ?? 'VoiceVitals',
                      style: AppTypography.titleLarge(
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                    Text(
                      subtitleOverride ?? 'Clinical Workspace',
                      style: AppTypography.labelSmall(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right area: Custom trailing or Doctor Avatar
            if (trailing != null)
              trailing!
            else if (showAvatar)
              GestureDetector(
                onTap: () => DoctorProfileSheet.show(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'DA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 38),
          ],
        ),
      ),
    );
  }
}
