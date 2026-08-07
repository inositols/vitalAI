import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

class ChatMessageActionBar extends StatelessWidget {
  final bool? feedbackIsPositive;
  final bool isSpeaking;
  final VoidCallback onCopy;
  final VoidCallback onToggleThumbsUp;
  final VoidCallback onToggleThumbsDown;
  final VoidCallback onToggleSpeech;
  final VoidCallback? onRegenerate;

  const ChatMessageActionBar({
    super.key,
    required this.feedbackIsPositive,
    required this.isSpeaking,
    required this.onCopy,
    required this.onToggleThumbsUp,
    required this.onToggleThumbsDown,
    required this.onToggleSpeech,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 16),
            tooltip: 'Copy response',
            visualDensity: VisualDensity.compact,
            color: context.colorScheme.onSurfaceVariant,
            onPressed: onCopy,
          ),
          IconButton(
            icon: Icon(
              feedbackIsPositive == true
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              size: 16,
              color: feedbackIsPositive == true
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Good response',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleThumbsUp,
          ),
          IconButton(
            icon: Icon(
              feedbackIsPositive == false
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              size: 16,
              color: feedbackIsPositive == false
                  ? context.colorScheme.error
                  : context.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Poor response',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleThumbsDown,
          ),
          IconButton(
            icon: Icon(
              isSpeaking
                  ? Icons.volume_up
                  : Icons.volume_up_outlined,
              size: 16,
              color: isSpeaking
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Read Aloud',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleSpeech,
          ),
          if (onRegenerate != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              tooltip: 'Regenerate',
              visualDensity: VisualDensity.compact,
              color: context.colorScheme.onSurfaceVariant,
              onPressed: onRegenerate,
            ),
        ],
      ),
    );
  }
}
