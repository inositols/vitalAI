import 'package:equatable/equatable.dart';

/// Predefined standard GenUI action types recognized by the conversation engine.
enum GenUiActionType {
  compareVitals,
  viewVitalHistory,
  generateSummary,
  recordVitals,
  viewPatient,
  editPatient,
  confirmSave,
  cancelWorkflow,
  addInformation,
  changeDateRange,
  viewIndividualReadings,
  viewTrends,
  askQuestion,
  skipField,
  custom;

  static GenUiActionType fromString(String? value) {
    if (value == null) return GenUiActionType.custom;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'compare_vitals':
      case 'comparevitals':
        return GenUiActionType.compareVitals;
      case 'view_vital_history':
      case 'viewvitalhistory':
      case 'view_history':
        return GenUiActionType.viewVitalHistory;
      case 'generate_summary':
      case 'generatesummary':
      case 'summarize':
      case 'summary':
        return GenUiActionType.generateSummary;
      case 'record_vitals':
      case 'recordvitals':
      case 'add_vitals':
        return GenUiActionType.recordVitals;
      case 'view_patient':
      case 'viewpatient':
      case 'view_profile':
        return GenUiActionType.viewPatient;
      case 'edit_patient':
      case 'editpatient':
      case 'edit_details':
        return GenUiActionType.editPatient;
      case 'confirm_save':
      case 'confirmsave':
      case 'confirm':
      case 'save':
        return GenUiActionType.confirmSave;
      case 'cancel_workflow':
      case 'cancelworkflow':
      case 'cancel':
        return GenUiActionType.cancelWorkflow;
      case 'add_information':
      case 'addinformation':
      case 'add_more':
        return GenUiActionType.addInformation;
      case 'change_date_range':
      case 'changedaterange':
        return GenUiActionType.changeDateRange;
      case 'view_individual_readings':
      case 'viewindividualreadings':
      case 'individual_readings':
        return GenUiActionType.viewIndividualReadings;
      case 'view_trends':
      case 'viewtrends':
      case 'trends':
        return GenUiActionType.viewTrends;
      case 'ask_question':
      case 'askquestion':
        return GenUiActionType.askQuestion;
      case 'skip_field':
      case 'skipfield':
      case 'skip':
        return GenUiActionType.skipField;
      default:
        return GenUiActionType.custom;
    }
  }

  String toSnakeCase() {
    switch (this) {
      case GenUiActionType.compareVitals:
        return 'compare_vitals';
      case GenUiActionType.viewVitalHistory:
        return 'view_vital_history';
      case GenUiActionType.generateSummary:
        return 'generate_summary';
      case GenUiActionType.recordVitals:
        return 'record_vitals';
      case GenUiActionType.viewPatient:
        return 'view_patient';
      case GenUiActionType.editPatient:
        return 'edit_patient';
      case GenUiActionType.confirmSave:
        return 'confirm_save';
      case GenUiActionType.cancelWorkflow:
        return 'cancel_workflow';
      case GenUiActionType.addInformation:
        return 'add_information';
      case GenUiActionType.changeDateRange:
        return 'change_date_range';
      case GenUiActionType.viewIndividualReadings:
        return 'view_individual_readings';
      case GenUiActionType.viewTrends:
        return 'view_trends';
      case GenUiActionType.askQuestion:
        return 'ask_question';
      case GenUiActionType.skipField:
        return 'skip_field';
      case GenUiActionType.custom:
        return 'custom';
    }
  }
}

/// A strongly-typed interactive GenUI action button, chip, or link.
class GenUiAction extends Equatable {
  final String id;
  final GenUiActionType type;
  final String label;
  final Map<String, dynamic> payload;
  final String? iconName;
  final bool isDestructive;
  final bool requiresConfirmation;

  const GenUiAction({
    required this.id,
    required this.type,
    required this.label,
    this.payload = const {},
    this.iconName,
    this.isDestructive = false,
    this.requiresConfirmation = false,
  });

  factory GenUiAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? json['action']?.toString();
    return GenUiAction(
      id: json['id']?.toString() ?? json['action']?.toString() ?? UniqueKeyId.generate(),
      type: GenUiActionType.fromString(typeStr),
      label: json['label']?.toString() ?? json['title']?.toString() ?? 'Action',
      payload: (json['payload'] is Map)
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : (json['data'] is Map)
              ? Map<String, dynamic>.from(json['data'] as Map)
              : {},
      iconName: json['icon']?.toString() ?? json['iconName']?.toString(),
      isDestructive: json['isDestructive'] == true,
      requiresConfirmation: json['requiresConfirmation'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toSnakeCase(),
        'label': label,
        'payload': payload,
        if (iconName != null) 'icon': iconName,
        'isDestructive': isDestructive,
        'requiresConfirmation': requiresConfirmation,
      };

  GenUiAction copyWith({
    String? id,
    GenUiActionType? type,
    String? label,
    Map<String, dynamic>? payload,
    String? iconName,
    bool? isDestructive,
    bool? requiresConfirmation,
  }) {
    return GenUiAction(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      payload: payload ?? this.payload,
      iconName: iconName ?? this.iconName,
      isDestructive: isDestructive ?? this.isDestructive,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        payload,
        iconName,
        isDestructive,
        requiresConfirmation,
      ];
}

class UniqueKeyId {
  static int _counter = 0;
  static String generate() => 'action_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
}

