import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. (+) Context Attachment Button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 26,
              ),
              tooltip: 'Attach Clinical Context',
              onPressed: onAttachContext,
            ),
            const SizedBox(width: 4),

            // 2. Rounded Pill Text Field with Inside Mic
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about your health...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty && !isGenerating) {
                            onSend();
                          }
                        },
                      ),
                    ),
                    // Mic inside textfield
                    IconButton(
                      icon: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF0062E0),
                        size: 22,
                      ),
                      tooltip: 'Voice Input',
                      onPressed: onVoiceInput,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 3. Electric Blue Circular Send Button
            GestureDetector(
              onTap: isGenerating ? null : onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF0062E0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 22,
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
