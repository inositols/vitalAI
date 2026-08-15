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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultSuggestions = suggestions.isNotEmpty
        ? suggestions
        : [
            'Explain BP readings',
            'Is my heart rate normal?',
            'How to lower blood pressure?',
            'Summary for doctor',
          ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: defaultSuggestions.length,
        itemBuilder: (ctx, index) {
          final text = defaultSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelectSuggestion(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
