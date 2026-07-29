import 'package:flutter/material.dart';
import '../extensions/build_context_ext.dart';
import '../theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.borderRadius = AppRadius.xl,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final effectiveColor = backgroundColor ?? (isDark ? AppColors.darkCard : Colors.white);
    final defaultBorder = Border.all(
      color: isDark
          ? AppColors.darkBorder
          : context.colorScheme.outlineVariant.withValues(alpha: 0.6),
      width: 1,
    );
    final effectiveBorder = border ?? defaultBorder;
    final effectiveShadow = boxShadow ?? AppShadows.subtle(context);

    final cardContent = Padding(
      padding: padding ?? AppSpacing.cardPadding,
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadow,
      ),
      child: Material(
        color: gradient == null ? effectiveColor : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? effectiveColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: effectiveBorder,
          ),
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  splashColor: context.colorScheme.primary.withValues(alpha: 0.08),
                  highlightColor: context.colorScheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: cardContent,
                )
              : cardContent,
        ),
      ),
    );
  }
}
