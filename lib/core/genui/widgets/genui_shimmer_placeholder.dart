import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Shimmer placeholder rendered during progressive GenUI hydration and streaming payload generation.
class GenUiShimmerPlaceholder extends StatefulWidget {
  final String label;
  final double height;

  const GenUiShimmerPlaceholder({
    super.key,
    this.label = 'Synthesizing clinical visualization...',
    this.height = 140,
  });

  @override
  State<GenUiShimmerPlaceholder> createState() => _GenUiShimmerPlaceholderState();
}

class _GenUiShimmerPlaceholderState extends State<GenUiShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Container(
        width: double.infinity,
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Generating clinical interactive card: ${widget.label}',
      container: true,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final progress = _shimmerController.value;
          final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
          final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

          return Container(
            width: double.infinity,
            height: widget.height,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              gradient: LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                stops: [
                  (progress - 0.3).clamp(0.0, 1.0),
                  progress.clamp(0.0, 1.0),
                  (progress + 0.3).clamp(0.0, 1.0),
                ],
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 10,
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
