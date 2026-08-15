import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onAvatarTap;
  final String? avatarUrl;
  final String? initials;

  const AppTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.onAvatarTap,
    this.avatarUrl,
    this.initials,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                // Signature Medical Cross Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A365C) : const Color(0xFFD6E9FF),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Color(0xFF0062E0),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            trailing ??
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF2A365C) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFFEBF5FF),
                      child: Text(
                        (initials != null && initials!.isNotEmpty)
                            ? initials![0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Color(0xFF0062E0),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
