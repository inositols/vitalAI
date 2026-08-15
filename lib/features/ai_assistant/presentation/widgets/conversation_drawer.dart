import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
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

  void _confirmDeleteConversation(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteConversation(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Conversations?'),
        content: const Text('Are you sure you want to clear your entire chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onClearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Map<String, List<ChatConversation>> _groupConversations(List<ChatConversation> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<ChatConversation>> groups = {
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    for (final c in list) {
      final cDate = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      if (cDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(c);
      } else if (cDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(c);
      } else if (cDate.isAfter(lastWeek)) {
        groups['Previous 7 Days']!.add(c);
      } else {
        groups['Older']!.add(c);
      }
    }

    groups.removeWhere((key, val) => val.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    final filtered = widget.conversations.where((c) {
      final titleMatch = c.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final msgMatch = c.messages.any(
        (m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
      return titleMatch || msgMatch;
    }).toList();

    final grouped = _groupConversations(filtered);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Row (Safely constrained to never overflow)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            gradient: AppColors.aiGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Chat Sessions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search chat topics & records...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            const Divider(height: 10),

            // Conversation Groups
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No conversation sessions found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: grouped.keys.length,
                      itemBuilder: (ctx, groupIdx) {
                        final groupTitle = grouped.keys.elementAt(groupIdx);
                        final items = grouped[groupTitle]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Text(
                                groupTitle.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            ...items.map((conv) {
                              final isActive = conv.id == widget.activeConversationId;
                              final msgCount = conv.messages.length;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? context.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isActive
                                      ? Border.all(color: context.colorScheme.primary.withValues(alpha: 0.4))
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : (isDark ? AppColors.darkContainer : const Color(0xFFF1F5F9)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                        color: isActive ? AppColors.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        size: 16,
                                      ),
                                    ),
                                    title: Text(
                                      conv.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                        color: isActive ? context.colorScheme.primary : null,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '$msgCount ${msgCount == 1 ? 'message' : 'messages'}',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                                      tooltip: 'Delete session',
                                      onPressed: () => _confirmDeleteConversation(context, conv.id, conv.title),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onSelectConversation(conv.id);
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
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
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Clear All Conversations', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => _confirmClearAll(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
