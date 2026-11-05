import 'package:flutter/material.dart';
import '../components/suggestion_card.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';
import '../models/genui_response.dart';
import 'genui_callbacks.dart';
import 'genui_registry.dart';

/// Renders a [GenUiResponse] or list of [GenUiComponent] models dynamically using [GenUiRegistry].
class GenUiResponseRenderer extends StatelessWidget {
  final GenUiResponse? response;
  final List<GenUiComponent>? components;
  final List<GenUiAction>? suggestions;
  final GenUiActionCallback? onActionSelected;
  final GenUiOptionCallback? onOptionSelected;
  final GenUiMultiOptionCallback? onMultiOptionSubmitted;
  final GenUiInputCallback? onInputSubmitted;
  final GenUiVoidCallback? onConfirm;
  final GenUiVoidCallback? onCancel;
  final GenUiVoidCallback? onSkip;

  const GenUiResponseRenderer({
    super.key,
    this.response,
    this.components,
    this.suggestions,
    this.onActionSelected,
    this.onOptionSelected,
    this.onMultiOptionSubmitted,
    this.onInputSubmitted,
    this.onConfirm,
    this.onCancel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final activeComponents = components ?? response?.components ?? const [];
    final activeSuggestions = suggestions ?? response?.suggestions ?? const [];

    final handlers = GenUiHandlers(
      onActionSelected: onActionSelected,
      onOptionSelected: onOptionSelected,
      onMultiOptionSubmitted: onMultiOptionSubmitted,
      onInputSubmitted: onInputSubmitted,
      onConfirm: onConfirm,
      onCancel: onCancel,
      onSkip: onSkip,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final component in activeComponents)
          GenUiRegistry.instance.render(context, component, handlers),
        if (activeSuggestions.isNotEmpty)
          SuggestionCard(
            component: const GenUiComponent(
              id: 'bottom_suggestions',
              type: GenUiComponentTypes.suggestionCard,
            ),
            overrideActions: activeSuggestions,
            onActionSelected: onActionSelected,
          ),
      ],
    );
  }
}

/// Alias for engine renderer naming
typedef GenUiEngineRenderer = GenUiResponseRenderer;

