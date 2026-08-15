import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasInputText;
  final bool isGenerating;
  final VoidCallback onAttachContext;
  final VoidCallback onVoiceInput;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.hasInputText,
    required this.isGenerating,
    required this.onAttachContext,
    required this.onVoiceInput,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Context Attachment Button
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: 'Attach Clinical Context',
                onPressed: onAttachContext,
              ),
            ),
            const SizedBox(width: 8),

            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        minLines: 1,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask your AI clinical companion...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty && !isGenerating) {
                            onSend();
                          }
                        },
                      ),
                    ),
                    if (hasInputText)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        tooltip: 'Clear text',
                        onPressed: () => controller.clear(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mic or Send Button
            if (!hasInputText)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.tertiary,
                    size: 22,
                  ),
                  tooltip: 'Voice Input',
                  onPressed: onVoiceInput,
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  onPressed: isGenerating ? null : onSend,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
