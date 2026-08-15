import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Formatted rich text widget designed specifically for clinical AI responses and GenUI text segments.
/// Handles markdown bold (**text**), bullet points (•, -), numbered lists, emergency notices, and disclaimers.
class GenUiFormattedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const GenUiFormattedText({
    super.key,
    required this.text,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          height: 1.55,
          fontSize: 14.5,
        ) ??
        const TextStyle(fontSize: 14.5, height: 1.55);

    final paragraphs = text.split('\n');
    final List<Widget> children = [];

    for (int i = 0; i < paragraphs.length; i++) {
      final line = paragraphs[i].trim();
      if (line.isEmpty) {
        if (i < paragraphs.length - 1) {
          children.add(const SizedBox(height: 6));
        }
        continue;
      }

      // 1. Emergency Crisis Alert Callout
      if (line.startsWith('⚠️') || line.toUpperCase().contains('EMERGENCY NOTICE:')) {
        children.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: isDark ? 0.25 : 0.8),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.replaceAll('⚠️', '').trim(),
                    style: defaultStyle.copyWith(
                      color: isDark ? const Color(0xFFFCA5A5) : AppColors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 2. Educational / Medical Disclaimer Note (e.g., *Disclaimer: ...*)
      if (line.startsWith('*Disclaimer') || line.startsWith('Disclaimer:')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.replaceAll('*', '').trim(),
                    style: defaultStyle.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Bullet Point or Numbered List Line
      final isBullet = line.startsWith('- ') || line.startsWith('• ') || line.startsWith('* ');
      final isNumbered = RegExp(r'^\d+\.').hasMatch(line);

      if (isBullet || isNumbered) {
        String marker;
        String contentText;

        if (isBullet) {
          marker = '•';
          contentText = line.substring(2).trim();
        } else {
          final match = RegExp(r'^\d+\.').firstMatch(line)!;
          marker = match.group(0)!;
          contentText = line.substring(marker.length).trim();
        }

        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isNumbered ? 24 : 14,
                  child: Text(
                    marker,
                    style: defaultStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInlineRichText(contentText, defaultStyle),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Regular Paragraph with inline bold/italic
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildInlineRichText(line, defaultStyle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildInlineRichText(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        // Bold
        spans.add(TextSpan(
          text: matchedStr.substring(2, matchedStr.length - 2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        // Italic
        spans.add(TextSpan(
          text: matchedStr.substring(1, matchedStr.length - 1),
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        // Inline code/badge
        spans.add(TextSpan(
          text: matchedStr.substring(1, matchedStr.length - 1),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            backgroundColor: baseStyle.color?.withValues(alpha: 0.08),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
