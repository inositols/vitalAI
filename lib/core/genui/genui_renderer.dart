import 'package:flutter/material.dart';
import 'genui_parser.dart';
import 'builders/genui_widget_builder.dart';
import 'widgets/genui_formatted_text.dart';
import '../theme/design_tokens.dart';

/// Dynamic Generative UI Renderer widget that parses AI structured responses and composes pre-built Flutter widgets.
class GenUiRenderer extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;

  const GenUiRenderer({
    super.key,
    required this.content,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final components = GenUiParser.parseComponents(content);
    final cleanText = GenUiParser.cleanText(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cleanText.isNotEmpty)
          GenUiFormattedText(
            text: cleanText,
            baseStyle: textStyle,
          ),
        if (components.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...List.generate(components.length, (index) {
            final model = components[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey('${model.type}_$index'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 320 + (index * 100)),
              curve: AppMotion.easeOutCubic,
              builder: (ctx, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, (1 - opacity) * 12),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GenUiWidgetBuilder.build(context, model),
              ),
            );
          }),
        ],
      ],
    );
  }
}

