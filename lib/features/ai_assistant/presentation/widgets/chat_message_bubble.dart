import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/chat_message.dart';

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
  bool? _feedbackIsPositive; // null = none, true = thumbs up, false = thumbs down
  bool _isSpeaking = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleSpeech() {
    setState(() => _isSpeaking = !_isSpeaking);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSpeaking ? 'Playing voice audio...' : 'Audio stopped'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;

    if (message.isSystem) {
      return _buildSystemBubble(context, theme);
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
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiaryContainer,
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
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 6),
                          bottomRight: Radius.circular(isUser ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormattedContent(
                            context,
                            message.content,
                            isUser,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUser
                                      ? Colors.white70
                                      : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isFailed
                                      ? Icons.error_outline
                                      : isPending
                                          ? Icons.access_time
                                          : Icons.done_all,
                                  size: 12,
                                  color: isFailed
                                      ? Colors.redAccent
                                      : Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Gemini / ChatGPT AI Action Toolbar (Copy, Thumbs Up/Down, Regenerate, Audio)
                    if (!isUser && !isPending && !isFailed) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconButton(
                            icon: Icons.content_copy,
                            tooltip: 'Copy',
                            onPressed: () => _copyToClipboard(context),
                            theme: theme,
                          ),
                          _buildIconButton(
                            icon: _feedbackIsPositive == true
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            tooltip: 'Good Response',
                            color: _feedbackIsPositive == true
                                ? theme.colorScheme.primary
                                : null,
                            onPressed: () {
                              setState(() {
                                _feedbackIsPositive =
                                    _feedbackIsPositive == true ? null : true;
                              });
                            },
                            theme: theme,
                          ),
                          _buildIconButton(
                            icon: _feedbackIsPositive == false
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            tooltip: 'Bad Response',
                            color: _feedbackIsPositive == false
                                ? Colors.redAccent
                                : null,
                            onPressed: () {
                              setState(() {
                                _feedbackIsPositive =
                                    _feedbackIsPositive == false ? null : false;
                              });
                            },
                            theme: theme,
                          ),
                          if (widget.onRegenerate != null)
                            _buildIconButton(
                              icon: Icons.refresh,
                              tooltip: 'Regenerate',
                              onPressed: widget.onRegenerate,
                              theme: theme,
                            ),
                          _buildIconButton(
                            icon: _isSpeaking
                                ? Icons.volume_up
                                : Icons.volume_mute_outlined,
                            tooltip: 'Read Aloud',
                            color: _isSpeaking ? theme.colorScheme.primary : null,
                            onPressed: _toggleSpeech,
                            theme: theme,
                          ),
                          if (widget.onQuoteReply != null)
                            _buildIconButton(
                              icon: Icons.reply,
                              tooltip: 'Reply',
                              onPressed: () =>
                                  widget.onQuoteReply!(message.content),
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
          if (isFailed && widget.onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 40),
              child: TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.redAccent),
                label: const Text(
                  'Failed to send. Tap to retry',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ThemeData theme,
    Color? color,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 15,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: color ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSystemBubble(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.message.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(
      BuildContext context, String rawContent, bool isUser) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isUser ? Colors.white : theme.colorScheme.onSurface,
      height: 1.45,
    );

    final lines = rawContent.split('\n');
    final children = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('# ')) {
        children.add(
          Text(
            line.substring(2),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isUser ? Colors.white : theme.colorScheme.primary,
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        children.add(
          Text(
            line.substring(3),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isUser ? Colors.white : theme.colorScheme.secondary,
            ),
          ),
        );
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: textStyle?.copyWith(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: textStyle,
                ),
              ),
            ],
          ),
        );
      } else if (line.contains('⚠️') || line.contains('EMERGENCY')) {
        children.add(
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Text(
              line,
              style: textStyle?.copyWith(
                color: isUser ? Colors.white : Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        children.add(Text(line, style: textStyle));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
