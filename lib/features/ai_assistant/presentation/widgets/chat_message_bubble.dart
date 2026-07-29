import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/build_context_ext.dart';
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
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isUser ? AppColors.primaryGradient : null,
                        color: isUser
                            ? null
                            : isFailed
                                ? AppColors.errorContainer
                                : (isDark ? AppColors.darkCard : Colors.white),
                        border: isUser || isFailed
                            ? null
                            : Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: isUser
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : AppShadows.subtle(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            message.content,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: isUser
                                  ? Colors.white
                                  : isFailed
                                      ? AppColors.error
                                      : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isUser
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                ),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 6),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
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

  Widget _buildSystemBubble(BuildContext context) {
    final isDark = context.isDarkMode;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
        ),
      ),
    );
  }
}
