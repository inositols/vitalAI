import 'package:flutter/material.dart';
import '../../data/models/chat_conversation.dart';

class ConversationDrawer extends StatefulWidget {
  final List<ChatConversation> conversations;
  final String activeConversationId;
  final Function(String id) onSelectConversation;
  final Function(String id) onDeleteConversation;
  final VoidCallback onNewChat;
  final VoidCallback onClearAll;

  const ConversationDrawer({
    super.key,
    required this.conversations,
    required this.activeConversationId,
    required this.onSelectConversation,
    required this.onDeleteConversation,
    required this.onNewChat,
    required this.onClearAll,
  });

  @override
  State<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends State<ConversationDrawer> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.conversations.where((c) {
      final titleMatch = c.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final msgMatch = c.messages.any(
        (m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
      return titleMatch || msgMatch;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Chat'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onNewChat();
                  },
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chat conversations...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const Divider(height: 16),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No conversation sessions found.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final conv = filtered[index];
                      final isActive = conv.id == widget.activeConversationId;
                      final dateStr =
                          '${conv.updatedAt.month}/${conv.updatedAt.day}';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isActive
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          title: Text(
                            conv.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${conv.messages.length} messages • $dateStr',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: theme.colorScheme.error.withValues(alpha: 0.7),
                            onPressed: () {
                              widget.onDeleteConversation(conv.id);
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectConversation(conv.id);
                          },
                        ),
                      );
                    },
                  ),
          ),

          if (widget.conversations.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.cleaning_services, size: 18),
                  label: const Text('Clear All Conversations'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onClearAll();
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
