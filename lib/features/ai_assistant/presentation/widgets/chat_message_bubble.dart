import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/genui/genui_renderer.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/chat_message.dart';
import 'chat_message_action_bar.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final Function(String text)? onQuoteReply;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onQuoteReply,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool? _feedbackIsPositive;
  bool _isSpeaking = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    context.showSnackBar('Response copied to clipboard');
  }

  void _toggleSpeech() {
    setState(() => _isSpeaking = !_isSpeaking);
    context.showSnackBar(_isSpeaking ? 'Playing audio preview...' : 'Audio playback stopped');
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isDark = context.isDarkMode;

    if (message.isSystem) {
      return _buildSystemBubble(context);
    }

    final isUser = message.isUser;
    final isFailed = message.status == 'failed';
    final isPending = message.status == 'pending';
    final isEmergency = !isUser && message.content.contains('EMERGENCY NOTICE:');
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    if (!isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header (Avatar, Name, Timestamp)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VitalAI Assistant',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Full Width AI Response Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isEmergency
                    ? (isDark ? const Color(0xFF3B1219) : const Color(0xFFFEF2F2))
                    : isFailed
                        ? AppColors.errorContainer
                        : (isDark ? AppColors.darkCard : Colors.white),
                border: Border.all(
                  color: isEmergency
                      ? AppColors.error.withValues(alpha: 0.6)
                      : isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                  width: isEmergency ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.subtle(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFailed)
                    GenUiRenderer(
                      content: message.content,
                      textStyle: context.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        height: 1.5,
                        fontSize: 14.5,
                      ),
                    )
                  else
                    SelectableText(
                      message.content,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        height: 1.5,
                        fontSize: 14.5,
                      ),
                    ),
                ],
              ),
            ),
            if (isFailed && widget.onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Failed to send. Tap to retry', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  onPressed: widget.onRetry,
                ),
              ),
            if (!isPending && !isFailed)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                child: ChatMessageActionBar(
                  feedbackIsPositive: _feedbackIsPositive,
                  isSpeaking: _isSpeaking,
                  onCopy: () => _copyToClipboard(context),
                  onQuote: widget.onQuoteReply != null
                      ? () => widget.onQuoteReply!(message.content)
                      : null,
                  onToggleThumbsUp: () {
                    setState(() {
                      _feedbackIsPositive =
                          _feedbackIsPositive == true ? null : true;
                    });
                  },
                  onToggleThumbsDown: () {
                    setState(() {
                      _feedbackIsPositive =
                          _feedbackIsPositive == false ? null : false;
                    });
                  },
                  onToggleSpeech: _toggleSpeech,
                  onRegenerate: widget.onRegenerate,
                ),
              ),
          ],
        ),
      );
    }

    // User Message Bubble
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.content.startsWith('Regarding: "'))
                  _buildQuoteHeader(context, message.content),
                SelectableText(
                  message.content.startsWith('Regarding: "')
                      ? _extractUserBody(message.content)
                      : message.content,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    if (!isPending && !isFailed) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isFailed && widget.onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Failed to send. Tap to retry', style: TextStyle(color: AppColors.error, fontSize: 12)),
                onPressed: widget.onRetry,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteHeader(BuildContext context, String content) {
    final firstLine = content.split('\n').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: const Border(left: BorderSide(color: Colors.white70, width: 3)),
      ),
      child: Text(
        firstLine,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _extractUserBody(String content) {
    final lines = content.split('\n');
    if (lines.length > 1) {
      return lines.sublist(1).join('\n').trim();
    }
    return content;
  }

  Widget _buildSystemBubble(BuildContext context) {
    final isDark = context.isDarkMode;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(
          widget.message.content,
          style: context.textTheme.labelSmall?.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
