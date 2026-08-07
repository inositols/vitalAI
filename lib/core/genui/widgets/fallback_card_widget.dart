import 'package:flutter/material.dart';
import '../models/genui_component_model.dart';
import '../../theme/design_tokens.dart';

/// Fallback Widget for handling unknown or unrecognized GenUI component types gracefully.
class FallbackCardWidget extends StatelessWidget {
  final GenUiFallbackModel model;

  const FallbackCardWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.extension_outlined,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Component (${model.unknownType})',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (model.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    model.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
