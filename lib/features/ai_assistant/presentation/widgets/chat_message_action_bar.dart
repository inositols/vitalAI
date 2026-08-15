import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';

class ChatMessageActionBar extends StatelessWidget {
  final bool? feedbackIsPositive;
  final bool isSpeaking;
  final VoidCallback onCopy;
  final VoidCallback onToggleThumbsUp;
  final VoidCallback onToggleThumbsDown;
  final VoidCallback onToggleSpeech;
  final VoidCallback? onQuote;
  final VoidCallback? onRegenerate;

  const ChatMessageActionBar({
    super.key,
    required this.feedbackIsPositive,
    required this.isSpeaking,
    required this.onCopy,
    required this.onToggleThumbsUp,
    required this.onToggleThumbsDown,
    required this.onToggleSpeech,
    this.onQuote,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.copy_rounded,
            tooltip: 'Copy response',
            color: iconColor,
            onTap: onCopy,
          ),
          if (onQuote != null)
            _buildActionButton(
              icon: Icons.reply_rounded,
              tooltip: 'Quote in reply',
              color: iconColor,
              onTap: onQuote!,
            ),
          _buildActionButton(
            icon: feedbackIsPositive == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            tooltip: 'Helpful',
            color: feedbackIsPositive == true ? AppColors.secondary : iconColor,
            onTap: onToggleThumbsUp,
          ),
          _buildActionButton(
            icon: feedbackIsPositive == false ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
            tooltip: 'Not helpful',
            color: feedbackIsPositive == false ? AppColors.error : iconColor,
            onTap: onToggleThumbsDown,
          ),
          _buildActionButton(
            icon: isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
            tooltip: isSpeaking ? 'Stop audio' : 'Read aloud',
            color: isSpeaking ? AppColors.tertiary : iconColor,
            onTap: onToggleSpeech,
          ),
          if (onRegenerate != null)
            _buildActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Regenerate response',
              color: iconColor,
              onTap: onRegenerate!,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: color,
      onPressed: onTap,
    );
  }
}
