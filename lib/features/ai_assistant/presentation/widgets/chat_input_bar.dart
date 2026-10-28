import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// Clean, seamless input bar for VitalAI chat without nested boxes or redundant borders.
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
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. (+) Attachment Button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 26,
              ),
              tooltip: 'Attach Health Context',
              onPressed: onAttachContext,
            ),

            // 2. Seamless Plain Text Field (No nested box or extra borders)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask VitalAI anything...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && !isGenerating) {
                      onSend();
                    }
                  },
                ),
              ),
            ),

            // 3. Microphone Voice Button
            IconButton(
              icon: Icon(
                Icons.mic_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 24,
              ),
              tooltip: 'Voice Input',
              onPressed: onVoiceInput,
            ),

            // 4. Clean Circular Send Button
            Material(
              color: (hasText && !isGenerating)
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (hasText && !isGenerating) ? onSend : null,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: (hasText && !isGenerating)
                          ? Colors.white
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      size: 20,
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
