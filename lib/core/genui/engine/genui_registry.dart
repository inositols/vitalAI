import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../components/chart_card.dart';
import '../components/choice_card.dart';
import '../components/clinical_summary_card.dart';
import '../components/confirmation_card.dart';
import '../components/editable_patient_card.dart';
import '../components/follow_up_card.dart';
import '../components/patient_card.dart';
import '../components/success_card.dart';
import '../components/suggestion_card.dart';
import '../components/vital_input_card.dart';
import '../models/genui_component.dart';
import 'genui_callbacks.dart';

/// Bundle of event callbacks that any GenUI widget can invoke.
class GenUiHandlers {
  final GenUiActionCallback? onActionSelected;
  final GenUiOptionCallback? onOptionSelected;
  final GenUiMultiOptionCallback? onMultiOptionSubmitted;
  final GenUiInputCallback? onInputSubmitted;
  final GenUiVoidCallback? onConfirm;
  final GenUiVoidCallback? onCancel;
  final GenUiVoidCallback? onSkip;

  const GenUiHandlers({
    this.onActionSelected,
    this.onOptionSelected,
    this.onMultiOptionSubmitted,
    this.onInputSubmitted,
    this.onConfirm,
    this.onCancel,
    this.onSkip,
  });
}

typedef GenUiComponentBuilder = Widget Function(
  BuildContext context,
  GenUiComponent component,
  GenUiHandlers handlers,
);

/// Approved, controlled component registry preventing execution of arbitrary AI code.
class GenUiRegistry {
  static final GenUiRegistry instance = GenUiRegistry._internal();

  final Map<String, GenUiComponentBuilder> _builders = {};

  GenUiRegistry._internal() {
    _registerDefaultComponents();
  }

  void _registerDefaultComponents() {
    register(GenUiComponentTypes.suggestionCard, (context, component, handlers) {
      return SuggestionCard(
        component: component,
        onActionSelected: handlers.onActionSelected,
      );
    });

    register(GenUiComponentTypes.choiceCard, (context, component, handlers) {
      return ChoiceCard(
        component: component,
        isMultiple: false,
        onOptionSelected: handlers.onOptionSelected,
        onMultiOptionSubmitted: handlers.onMultiOptionSubmitted,
      );
    });

    register(GenUiComponentTypes.singleChoice, (context, component, handlers) {
      return ChoiceCard(
        component: component,
        isMultiple: false,
        onOptionSelected: handlers.onOptionSelected,
      );
    });

    register(GenUiComponentTypes.multipleChoice, (context, component, handlers) {
      return ChoiceCard(
        component: component,
        isMultiple: true,
        onMultiOptionSubmitted: handlers.onMultiOptionSubmitted,
      );
    });

    register(GenUiComponentTypes.followUpCard, (context, component, handlers) {
      return FollowUpCard(
        component: component,
        onAnswerSubmitted: handlers.onInputSubmitted,
        onSkip: handlers.onSkip,
        onCancel: handlers.onCancel,
      );
    });

    register(GenUiComponentTypes.patientCard, (context, component, handlers) {
      return PatientCard(
        component: component,
        onPatientSelected: handlers.onOptionSelected,
      );
    });

    register(GenUiComponentTypes.patientSelection, (context, component, handlers) {
      return PatientCard(
        component: component,
        onPatientSelected: handlers.onOptionSelected,
      );
    });

    register(GenUiComponentTypes.editablePatientCard, (context, component, handlers) {
      return EditablePatientCard(
        component: component,
        onUpdateFields: handlers.onInputSubmitted,
        onActionSelected: handlers.onActionSelected,
        onConfirmSave: handlers.onConfirm,
        onCancel: handlers.onCancel,
      );
    });

    register(GenUiComponentTypes.vitalInputCard, (context, component, handlers) {
      return VitalInputCard(
        component: component,
        onSaveVitals: handlers.onInputSubmitted,
        onActionSelected: handlers.onActionSelected,
        onCancel: handlers.onCancel,
      );
    });

    register(GenUiComponentTypes.clinicalSummaryCard, (context, component, handlers) {
      return ClinicalSummaryCard(
        component: component,
        onActionSelected: handlers.onActionSelected,
      );
    });

    register(GenUiComponentTypes.chartCard, (context, component, handlers) {
      return ChartCard(
        component: component,
        onActionSelected: handlers.onActionSelected,
      );
    });

    register(GenUiComponentTypes.confirmationCard, (context, component, handlers) {
      return ConfirmationCard(
        component: component,
        onConfirm: handlers.onConfirm,
        onCancel: handlers.onCancel,
      );
    });

    register(GenUiComponentTypes.successCard, (context, component, handlers) {
      return SuccessCard(
        component: component,
        onActionSelected: handlers.onActionSelected,
      );
    });
  }

  void register(String type, GenUiComponentBuilder builder) {
    _builders[GenUiComponentTypes.normalize(type)] = builder;
  }

  bool isRegistered(String type) => _builders.containsKey(GenUiComponentTypes.normalize(type));

  Widget render(
    BuildContext context,
    GenUiComponent component,
    GenUiHandlers handlers,
  ) {
    final normalized = GenUiComponentTypes.normalize(component.type);
    final builder = _builders[normalized];

    if (builder == null) {
      return _buildFallbackWidget(component);
    }

    try {
      return builder(context, component, handlers);
    } catch (e) {
      return _buildErrorWidget(component, e.toString());
    }
  }

  Widget _buildFallbackWidget(GenUiComponent component) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets_outlined, size: 16, color: AppColors.lightTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unsupported component: "${component.type}". Displaying safe fallback.',
              style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(GenUiComponent component, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Error rendering component: $error',
        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
      ),
    );
  }
}

