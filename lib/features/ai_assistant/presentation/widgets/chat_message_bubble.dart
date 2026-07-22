import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/build_context_ext.dart';
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
    context.showSnackBar(_isSpeaking ? 'Playing voice audio...' : 'Audio stopped');
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    if (message.isSystem) {
      return _buildSystemBubble(context);
    }

    final isUser = message.isUser;
    final isFailed = message.status == 'failed';
    final isPending = message.status == 'pending';
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.primary,
                        context.colorScheme.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? context.colorScheme.primary
                            : isFailed
                                ? context.colorScheme.errorContainer
                                : context.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            message.content,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: isUser
                                  ? context.colorScheme.onPrimary
                                  : isFailed
                                      ? context.colorScheme.onErrorContainer
                                      : context.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUser
                                      ? context.colorScheme.onPrimary
                                          .withValues(alpha: 0.7)
                                      : context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 4),
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isUser && !isPending && !isFailed)
                      ChatMessageActionBar(
                        feedbackIsPositive: _feedbackIsPositive,
                        isSpeaking: _isSpeaking,
                        onCopy: () => _copyToClipboard(context),
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
                  ],
                ),
              ),
            ],
          ),
          if (isFailed && widget.onRetry != null)
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Failed to send. Tap to retry'),
              onPressed: widget.onRetry,
            ),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.message.content,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
