import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: context.colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Attach Context',
            onPressed: onAttachContext,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask Gemini health assistant...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty && !isGenerating) {
                  onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          if (!hasInputText)
            IconButton(
              icon: Icon(
                Icons.mic,
                color: context.colorScheme.primary,
              ),
              tooltip: 'Voice Input',
              onPressed: onVoiceInput,
            )
          else
            IconButton.filled(
              icon: isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward, size: 20),
              onPressed: isGenerating ? null : onSend,
            ),
        ],
      ),
    );
  }
}
