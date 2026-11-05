import 'package:equatable/equatable.dart';
import 'genui_action.dart';
import 'genui_option.dart';

/// Standard, approved GenUI component type constants.
class GenUiComponentTypes {
  static const String suggestionCard = 'suggestion_card';
  static const String suggestionList = 'suggestion_list';
  static const String choiceCard = 'choice_card';
  static const String singleChoice = 'single_choice';
  static const String multipleChoice = 'multiple_choice';
  static const String followUpCard = 'follow_up_card';
  static const String patientCard = 'patient_card';
  static const String patientSelection = 'patient_selection';
  static const String editablePatientCard = 'editable_patient_card';
  static const String vitalInputCard = 'vital_input_card';
  static const String clinicalSummaryCard = 'clinical_summary_card';
  static const String chartCard = 'chart_card';
  static const String confirmationCard = 'confirmation_card';
  static const String successCard = 'success_card';
  static const String vitalSummary = 'vital_summary';

  static const Set<String> all = {
    suggestionCard,
    suggestionList,
    choiceCard,
    singleChoice,
    multipleChoice,
    followUpCard,
    patientCard,
    patientSelection,
    editablePatientCard,
    vitalInputCard,
    clinicalSummaryCard,
    chartCard,
    confirmationCard,
    successCard,
    vitalSummary,
  };

  /// Normalizes aliases and variants into primary type keys.
  static String normalize(String? raw) {
    if (raw == null) return 'unknown';
    final trimmed = raw.trim().toLowerCase().replaceAll('-', '_');
    if (trimmed == 'suggestion_list' || trimmed == 'suggestions') return suggestionCard;
    if (trimmed == 'single_choice' || trimmed == 'multiple_choice') return choiceCard;
    if (trimmed == 'patient_selection' || trimmed == 'patient_list') return patientCard;
    if (trimmed == 'patient_edit' || trimmed == 'patient_details') return editablePatientCard;
    if (trimmed == 'vitals_input' || trimmed == 'vital_entry') return vitalInputCard;
    if (trimmed == 'trend_chart' || trimmed == 'comparison_chart') return chartCard;
    if (trimmed == 'patient_summary' || trimmed == 'health_summary') return clinicalSummaryCard;
    if (trimmed == 'confirmation') return confirmationCard;
    if (trimmed == 'success') return successCard;
    return trimmed;
  }
}

/// A strongly-typed schema-validated Generative UI component representation.
class GenUiComponent extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final List<GenUiAction> actions;
  final List<GenUiOption> options;

  const GenUiComponent({
    required this.id,
    required this.type,
    this.data = const {},
    this.actions = const [],
    this.options = const [],
  });

  factory GenUiComponent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'unknown';
    final normalizedType = GenUiComponentTypes.normalize(rawType);

    final rawData = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : Map<String, dynamic>.from(json);

    // Parse actions if provided in json or data
    final rawActions = (json['actions'] as List?) ??
        (rawData['actions'] as List?) ??
        (rawData['options'] is List && (normalizedType == GenUiComponentTypes.suggestionCard)
            ? rawData['options'] as List
            : null);

    final List<GenUiAction> parsedActions = [];
    if (rawActions != null) {
      for (final a in rawActions) {
        if (a is Map) {
          parsedActions.add(GenUiAction.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    // Parse options if provided
    final rawOptions = (json['options'] as List?) ??
        (rawData['options'] as List?) ??
        (rawData['choices'] as List?);

    final List<GenUiOption> parsedOptions = [];
    if (rawOptions != null && normalizedType != GenUiComponentTypes.suggestionCard) {
      for (final o in rawOptions) {
        if (o is Map) {
          parsedOptions.add(GenUiOption.fromJson(Map<String, dynamic>.from(o)));
        } else if (o != null) {
          parsedOptions.add(GenUiOption(
            id: o.toString(),
            label: o.toString(),
            value: o,
          ));
        }
      }
    }

    return GenUiComponent(
      id: json['id']?.toString() ?? rawData['id']?.toString() ?? UniqueComponentId.generate(),
      type: normalizedType,
      data: rawData,
      actions: parsedActions,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        if (actions.isNotEmpty) 'actions': actions.map((a) => a.toJson()).toList(),
        if (options.isNotEmpty) 'options': options.map((o) => o.toJson()).toList(),
      };

  String? get title => data['title']?.toString();
  String? get subtitle => data['subtitle']?.toString();
  String? get promptText => data['prompt']?.toString() ?? data['question']?.toString() ?? data['message']?.toString();

  bool get isSuggestionCard => type == GenUiComponentTypes.suggestionCard;
  bool get isChoiceCard => type == GenUiComponentTypes.choiceCard;
  bool get isFollowUpCard => type == GenUiComponentTypes.followUpCard;
  bool get isPatientCard => type == GenUiComponentTypes.patientCard;
  bool get isEditablePatientCard => type == GenUiComponentTypes.editablePatientCard;
  bool get isVitalInputCard => type == GenUiComponentTypes.vitalInputCard;
  bool get isClinicalSummaryCard => type == GenUiComponentTypes.clinicalSummaryCard;
  bool get isChartCard => type == GenUiComponentTypes.chartCard;
  bool get isConfirmationCard => type == GenUiComponentTypes.confirmationCard;
  bool get isSuccessCard => type == GenUiComponentTypes.successCard;

  GenUiComponent copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    List<GenUiAction>? actions,
    List<GenUiOption>? options,
  }) {
    return GenUiComponent(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      actions: actions ?? this.actions,
      options: options ?? this.options,
    );
  }

  @override
  List<Object?> get props => [id, type, data, actions, options];
}

class UniqueComponentId {
  static int _counter = 0;
  static String generate() => 'cmp_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
}

