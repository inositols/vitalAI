import 'package:flutter/material.dart';

class SmartSuggestionsBar extends StatelessWidget {
  final List<String> suggestions;
  final Function(String query) onSelectSuggestion;

  const SmartSuggestionsBar({
    super.key,
    required this.suggestions,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (ctx, index) {
          final text = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(text),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => onSelectSuggestion(text),
            ),
          );
        },
      ),
    );
  }
}
