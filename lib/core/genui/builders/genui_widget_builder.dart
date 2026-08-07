import 'package:flutter/material.dart';
import '../models/genui_component_model.dart';
import '../registry/widget_registry.dart';
import '../widgets/fallback_card_widget.dart';

/// Builder factory that safely resolves component models to interactive Flutter widgets.
class GenUiWidgetBuilder {
  static Widget build(BuildContext context, GenUiComponentModel model) {
    try {
      return WidgetRegistry().buildWidget(context, model);
    } catch (e) {
      debugPrint("GenUiWidgetBuilder error building component '${model.type}': $e");
      return FallbackCardWidget(
        model: GenUiFallbackModel(
          type: 'fallback_card',
          unknownType: model.type,
          message: 'Error rendering component payload',
        ),
      );
    }
  }
}
