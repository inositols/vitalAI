import 'package:equatable/equatable.dart';

/// Sealed base class for all Generative UI component models in Dart 3.
sealed class GenUiComponentModel extends Equatable {
  final String type;
  final Map<String, dynamic> rawJson;

  const GenUiComponentModel({
    required this.type,
    this.rawJson = const {},
  });

  @override
  List<Object?> get props => [type, rawJson];
}

/// Generic metric card model supporting BP, Glucose, Pulse, SpO2, Temp, Weight & Health Summaries.
final class GenUiMetricSummaryModel extends GenUiComponentModel {
  final String title;
  final String value;
  final String unit;
  final String status;
  final String? subtitle;
  final String? metricType; // 'bp', 'glucose', 'pulse', 'spo2', 'temp', 'weight'

  const GenUiMetricSummaryModel({
    required super.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    this.subtitle,
    this.metricType,
    super.rawJson,
  });

  factory GenUiMetricSummaryModel.fromJson(Map<String, dynamic> json) {
    return GenUiMetricSummaryModel(
      type: json['type']?.toString() ?? 'metric_summary',
      title: json['title']?.toString() ?? 'Health Metric',
      value: json['value']?.toString() ?? '--',
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? 'normal',
      subtitle: json['subtitle']?.toString(),
      metricType: json['metricType']?.toString() ?? json['metric']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, value, unit, status, subtitle, metricType];
}

/// Trend chart component model for single metric tracking over time.
final class GenUiTrendChartModel extends GenUiComponentModel {
  final String title;
  final String metricType;
  final List<double> dataPoints;
  final List<String> labels;
  final String? summary;

  const GenUiTrendChartModel({
    required super.type,
    required this.title,
    required this.metricType,
    required this.dataPoints,
    required this.labels,
    this.summary,
    super.rawJson,
  });

  factory GenUiTrendChartModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['dataPoints'] as List? ?? [];
    final rawLabels = json['labels'] as List? ?? [];

    return GenUiTrendChartModel(
      type: json['type']?.toString() ?? 'trend_chart',
      title: json['title']?.toString() ?? 'Vitals Trend',
      metricType: json['metricType']?.toString() ?? 'bp',
      dataPoints: rawPoints.map((e) => (e as num).toDouble()).toList(),
      labels: rawLabels.map((e) => e.toString()).toList(),
      summary: json['summary']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, metricType, dataPoints, labels, summary];
}

/// Comparison chart component model comparing two time periods or two metrics.
final class GenUiComparisonChartModel extends GenUiComponentModel {
  final String title;
  final String series1Name;
  final List<double> series1Data;
  final String series2Name;
  final List<double> series2Data;
  final List<String> labels;
  final String? comparisonNote;

  const GenUiComparisonChartModel({
    required super.type,
    required this.title,
    required this.series1Name,
    required this.series1Data,
    required this.series2Name,
    required this.series2Data,
    required this.labels,
    this.comparisonNote,
    super.rawJson,
  });

  factory GenUiComparisonChartModel.fromJson(Map<String, dynamic> json) {
    final rawS1 = json['series1Data'] as List? ?? json['thisWeek'] as List? ?? [];
    final rawS2 = json['series2Data'] as List? ?? json['lastWeek'] as List? ?? [];
    final rawLabels = json['labels'] as List? ?? [];

    return GenUiComparisonChartModel(
      type: json['type']?.toString() ?? 'comparison_chart',
      title: json['title']?.toString() ?? 'Vitals Comparison',
      series1Name: json['series1Name']?.toString() ?? 'Current Period',
      series1Data: rawS1.map((e) => (e as num).toDouble()).toList(),
      series2Name: json['series2Name']?.toString() ?? 'Previous Period',
      series2Data: rawS2.map((e) => (e as num).toDouble()).toList(),
      labels: rawLabels.map((e) => e.toString()).toList(),
      comparisonNote: json['comparisonNote']?.toString() ?? json['note']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, series1Name, series1Data, series2Name, series2Data, labels, comparisonNote];
}

/// Educational card component model with definition, illustration, normal range, and reading links.
final class GenUiEducationCardModel extends GenUiComponentModel {
  final String title;
  final String definition;
  final String? normalRange;
  final String? illustrationIcon;
  final List<String> relatedReading;
  final String? learnMoreUrl;

  const GenUiEducationCardModel({
    required super.type,
    required this.title,
    required this.definition,
    this.normalRange,
    this.illustrationIcon,
    this.relatedReading = const [],
    this.learnMoreUrl,
    super.rawJson,
  });

  factory GenUiEducationCardModel.fromJson(Map<String, dynamic> json) {
    final reading = json['relatedReading'] as List? ?? [];
    return GenUiEducationCardModel(
      type: json['type']?.toString() ?? 'education_card',
      title: json['title']?.toString() ?? json['heading']?.toString() ?? 'Health Education',
      definition: json['definition']?.toString() ?? json['tip']?.toString() ?? json['description']?.toString() ?? '',
      normalRange: json['normalRange']?.toString() ?? json['range']?.toString(),
      illustrationIcon: json['illustrationIcon']?.toString() ?? json['icon']?.toString(),
      relatedReading: reading.map((e) => e.toString()).toList(),
      learnMoreUrl: json['learnMoreUrl']?.toString() ?? json['link']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, definition, normalRange, illustrationIcon, relatedReading, learnMoreUrl];
}

/// AI Recommendation component model with priority, reason, related metric, and follow-up steps.
final class GenUiRecommendationCardModel extends GenUiComponentModel {
  final String title;
  final String priority; // 'high', 'medium', 'low'
  final String reason;
  final String? relatedMetric;
  final List<String> suggestedFollowUp;
  final String disclaimer;

  const GenUiRecommendationCardModel({
    required super.type,
    required this.title,
    required this.priority,
    required this.reason,
    this.relatedMetric,
    this.suggestedFollowUp = const [],
    required this.disclaimer,
    super.rawJson,
  });

  factory GenUiRecommendationCardModel.fromJson(Map<String, dynamic> json) {
    final followUp = json['suggestedFollowUp'] as List? ?? json['actions'] as List? ?? [];
    return GenUiRecommendationCardModel(
      type: json['type']?.toString() ?? 'recommendation_card',
      title: json['title']?.toString() ?? 'AI Health Recommendation',
      priority: json['priority']?.toString().toLowerCase() ?? 'medium',
      reason: json['reason']?.toString() ?? json['details']?.toString() ?? '',
      relatedMetric: json['relatedMetric']?.toString(),
      suggestedFollowUp: followUp.map((e) => e.toString()).toList(),
      disclaimer: json['disclaimer']?.toString() ??
          'This recommendation is for educational purposes only. Always consult a qualified healthcare professional before making medical decisions.',
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, priority, reason, relatedMetric, suggestedFollowUp, disclaimer];
}

/// Report card component model for dynamic medical report summaries with PDF download & share capabilities.
final class GenUiReportCardModel extends GenUiComponentModel {
  final String patientName;
  final String reportDate;
  final String summaryText;
  final Map<String, String> vitalsOverview;
  final List<String> aiObservations;
  final String? pdfDownloadRoute;

  const GenUiReportCardModel({
    required super.type,
    required this.patientName,
    required this.reportDate,
    required this.summaryText,
    required this.vitalsOverview,
    required this.aiObservations,
    this.pdfDownloadRoute,
    super.rawJson,
  });

  factory GenUiReportCardModel.fromJson(Map<String, dynamic> json) {
    final vitalsRaw = json['vitalsOverview'] as Map<String, dynamic>? ?? {};
    final obsRaw = json['aiObservations'] as List? ?? json['highlights'] as List? ?? [];

    return GenUiReportCardModel(
      type: json['type']?.toString() ?? 'report_card',
      patientName: json['patientName']?.toString() ?? 'Patient',
      reportDate: json['reportDate']?.toString() ?? 'Today',
      summaryText: json['summaryText']?.toString() ?? json['summary']?.toString() ?? 'Health Report',
      vitalsOverview: vitalsRaw.map((k, v) => MapEntry(k, v.toString())),
      aiObservations: obsRaw.map((e) => e.toString()).toList(),
      pdfDownloadRoute: json['pdfDownloadRoute']?.toString() ?? '/history',
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, patientName, reportDate, summaryText, vitalsOverview, aiObservations, pdfDownloadRoute];
}

/// Health timeline card model showing vital progression over multiple months.
final class GenUiTimelineCardModel extends GenUiComponentModel {
  final String title;
  final String timeSpan; // e.g. "Last 6 Months"
  final List<Map<String, String>> monthlyEvents; // [{month: 'Jan', note: 'BP 120/80'}]
  final List<String> highlights;

  const GenUiTimelineCardModel({
    required super.type,
    required this.title,
    required this.timeSpan,
    required this.monthlyEvents,
    required this.highlights,
    super.rawJson,
  });

  factory GenUiTimelineCardModel.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['monthlyEvents'] as List? ?? json['events'] as List? ?? [];
    final rawHighlights = json['highlights'] as List? ?? [];

    final parsedEvents = rawEvents.map((item) {
      if (item is Map) {
        return item.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return <String, String>{'note': item.toString()};
    }).toList();

    return GenUiTimelineCardModel(
      type: json['type']?.toString() ?? 'timeline_card',
      title: json['title']?.toString() ?? 'Health Timeline',
      timeSpan: json['timeSpan']?.toString() ?? 'Last 6 Months',
      monthlyEvents: parsedEvents,
      highlights: rawHighlights.map((e) => e.toString()).toList(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, timeSpan, monthlyEvents, highlights];
}

/// Reminder & medication card model.
final class GenUiReminderCardModel extends GenUiComponentModel {
  final String title;
  final String time;
  final String? dosage;
  final bool isCompleted;

  const GenUiReminderCardModel({
    required super.type,
    required this.title,
    required this.time,
    this.dosage,
    this.isCompleted = false,
    super.rawJson,
  });

  factory GenUiReminderCardModel.fromJson(Map<String, dynamic> json) {
    return GenUiReminderCardModel(
      type: json['type']?.toString() ?? 'reminder_card',
      title: json['title']?.toString() ?? json['medication']?.toString() ?? 'Reminder',
      time: json['time']?.toString() ?? json['schedule']?.toString() ?? '08:00 AM',
      dosage: json['dosage']?.toString(),
      isCompleted: json['isCompleted'] == true,
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, time, dosage, isCompleted];
}

/// AI Insight Card Model.
final class GenUiAiInsightCardModel extends GenUiComponentModel {
  final String title;
  final String insight;
  final String? category;

  const GenUiAiInsightCardModel({
    required super.type,
    required this.title,
    required this.insight,
    this.category,
    super.rawJson,
  });

  factory GenUiAiInsightCardModel.fromJson(Map<String, dynamic> json) {
    return GenUiAiInsightCardModel(
      type: json['type']?.toString() ?? 'ai_insight_card',
      title: json['title']?.toString() ?? 'AI Health Insight',
      insight: json['insight']?.toString() ?? json['text']?.toString() ?? '',
      category: json['category']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, insight, category];
}

/// Patient Profile Card Model.
final class GenUiPatientProfileCardModel extends GenUiComponentModel {
  final String name;
  final int age;
  final String gender;
  final String? primaryCondition;

  const GenUiPatientProfileCardModel({
    required super.type,
    required this.name,
    required this.age,
    required this.gender,
    this.primaryCondition,
    super.rawJson,
  });

  factory GenUiPatientProfileCardModel.fromJson(Map<String, dynamic> json) {
    return GenUiPatientProfileCardModel(
      type: json['type']?.toString() ?? 'patient_profile_card',
      name: json['name']?.toString() ?? 'Patient',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString() ?? 'Unspecified',
      primaryCondition: json['primaryCondition']?.toString() ?? json['condition']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, name, age, gender, primaryCondition];
}

/// Validated destination routes supported across VitalAI.
class GenUiValidRoutes {
  static const String dashboard = '/';
  static const String patients = '/patients';
  static const String charts = '/charts';
  static const String aiChat = '/ai-chat';
  static const String settings = '/settings';
  static const String reminders = '/reminders';
  static const String history = '/history';
  static const String caregiver = '/caregiver';
  static const String addVital = '/add-vital';

  static const List<String> allRoutes = [
    dashboard,
    patients,
    charts,
    aiChat,
    settings,
    reminders,
    history,
    caregiver,
    addVital,
  ];

  /// Supported safe route destinations and semantic identifiers.
  static const Set<String> _safeDestinations = {
    '/',
    'dashboard',
    'home',
    '/patients',
    'patients',
    'patient_profile',
    '/charts',
    'charts',
    '/vitals',
    'vitals',
    'blood_pressure_history',
    'bp_history',
    'blood_pressure_charts',
    'bp_charts',
    'glucose_history',
    '/history',
    'history',
    'records',
    '/reminders',
    'reminders',
    'schedule',
    '/caregiver',
    'caregiver',
    '/settings',
    'settings',
    '/add-vital',
    'add_vital',
    'log_vital',
    '/ai-chat',
    'ai_chat',
    'chat',
  };

  /// Validates whether a model-generated destination is supported in our security whitelist.
  static bool isSafeDestination(String? destination) {
    if (destination == null || destination.trim().isEmpty) return false;
    return _safeDestinations.contains(destination.trim().toLowerCase());
  }

  /// Supported safe vital metrics.
  static const Set<String> _safeVitals = {
    'blood_pressure',
    'bp',
    'glucose',
    'blood_sugar',
    'sugar',
    'pulse',
    'heart_rate',
    'spo2',
    'oxygen',
    'temperature',
    'temp',
    'weight',
  };

  /// Validates whether a vital identifier is supported.
  static bool isSafeVital(String? vital) {
    if (vital == null || vital.trim().isEmpty) return false;
    return _safeVitals.contains(vital.trim().toLowerCase());
  }

  /// Resolves high-level semantic destination names or raw route strings into a verified app route.
  static String resolveRoute(String? destination) {
    if (destination == null || destination.trim().isEmpty) return dashboard;
    final clean = destination.trim().toLowerCase();

    if (clean == '/history' || clean.contains('history') || clean.contains('records')) {
      return history;
    }
    if (clean == '/charts' || clean == '/vitals' || clean.contains('chart') || clean.contains('trend')) {
      return charts;
    }
    if (clean == '/add-vital' || clean.contains('add') || clean.contains('log_vital')) {
      return addVital;
    }
    if (clean == '/reminders' || clean.contains('reminder') || clean.contains('schedule')) {
      return reminders;
    }
    if (clean == '/patients' || clean.contains('patient') || clean.contains('profile')) {
      return patients;
    }
    if (clean == '/caregiver' || clean.contains('caregiver')) {
      return caregiver;
    }
    if (clean == '/settings' || clean.contains('setting')) {
      return settings;
    }
    if (clean == '/ai-chat' || clean.contains('chat')) {
      return aiChat;
    }
    return dashboard;
  }
}

/// Action Button component model with verified route resolution.
final class GenUiActionButtonModel extends GenUiComponentModel {
  final String label;
  final String action;
  final String? route;

  const GenUiActionButtonModel({
    required super.type,
    required this.label,
    required this.action,
    this.route,
    super.rawJson,
  });

  /// Verified safe route destination.
  String get verifiedRoute => GenUiValidRoutes.resolveRoute(route);

  factory GenUiActionButtonModel.fromJson(Map<String, dynamic> json) {
    return GenUiActionButtonModel(
      type: json['type']?.toString() ?? 'action_button',
      label: json['label']?.toString() ?? json['text']?.toString() ?? 'Action',
      action: json['action']?.toString() ?? 'navigate',
      route: json['route']?.toString() ?? json['destination']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, label, action, route];
}

/// Conceptual action types for GenUI follow-up interactions.
enum GenUiActionType {
  followUpQuestion,
  navigation,
  dataAction,
  informationExpansion,
  unknown,
}

/// Strongly typed schema representing an individual contextual follow-up action or question.
class GenUiFollowUpAction extends Equatable {
  final String type;
  final String label;
  final String? prompt;
  final String? destination;
  final String? vital;
  final Map<String, dynamic> rawJson;

  const GenUiFollowUpAction({
    required this.type,
    required this.label,
    this.prompt,
    this.destination,
    this.vital,
    this.rawJson = const {},
  });

  GenUiActionType get actionType {
    final clean = type.toLowerCase().trim();
    if (clean == 'follow_up_question' || clean == 'follow_up') {
      return GenUiActionType.followUpQuestion;
    }
    if (clean == 'navigation' || clean == 'navigation_action' || clean == 'navigate') {
      return GenUiActionType.navigation;
    }
    if (clean == 'view_vital' || clean == 'data_action' || clean == 'vital_action') {
      return GenUiActionType.dataAction;
    }
    if (clean == 'information_expansion' || clean == 'expand') {
      return GenUiActionType.informationExpansion;
    }
    return GenUiActionType.unknown;
  }

  bool get isFollowUpQuestion =>
      actionType == GenUiActionType.followUpQuestion || actionType == GenUiActionType.informationExpansion;
  bool get isNavigation => actionType == GenUiActionType.navigation;
  bool get isDataAction => actionType == GenUiActionType.dataAction;
  bool get isInformationExpansion => actionType == GenUiActionType.informationExpansion;

  /// Effective prompt to query AI assistant.
  String get effectivePrompt {
    if (prompt != null && prompt!.trim().isNotEmpty) {
      return prompt!.trim();
    }
    return label.trim();
  }

  factory GenUiFollowUpAction.fromJson(Map<String, dynamic> json) {
    return GenUiFollowUpAction(
      type: json['type']?.toString() ?? 'follow_up_question',
      label: json['label']?.toString() ?? json['text']?.toString() ?? json['title']?.toString() ?? 'Follow-up',
      prompt: json['prompt']?.toString() ?? json['query']?.toString(),
      destination: json['destination']?.toString() ?? json['route']?.toString(),
      vital: json['vital']?.toString() ?? json['metric']?.toString(),
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        if (prompt != null) 'prompt': prompt,
        if (destination != null) 'destination': destination,
        if (vital != null) 'vital': vital,
      };

  @override
  List<Object?> get props => [type, label, prompt, destination, vital, rawJson];
}

/// GenUI component model for a group of suggested follow-up questions and actions.
final class GenUiFollowUpSuggestionsModel extends GenUiComponentModel {
  final String? title;
  final List<GenUiFollowUpAction> suggestions;

  const GenUiFollowUpSuggestionsModel({
    required super.type,
    this.title,
    required this.suggestions,
    super.rawJson,
  });

  factory GenUiFollowUpSuggestionsModel.fromJson(Map<String, dynamic> json) {
    final list = json['suggestions'] as List? ??
        json['actions'] as List? ??
        json['follow_ups'] as List? ??
        json['items'] as List? ??
        [];

    final parsed = list
        .whereType<Map<String, dynamic>>()
        .map((m) => GenUiFollowUpAction.fromJson(m))
        .toList();

    return GenUiFollowUpSuggestionsModel(
      type: json['type']?.toString() ?? 'follow_up_suggestions',
      title: json['title']?.toString(),
      suggestions: parsed,
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, title, suggestions];
}

/// GenUI component model wrapping a single follow-up action.
final class GenUiFollowUpActionModel extends GenUiComponentModel {
  final GenUiFollowUpAction action;

  const GenUiFollowUpActionModel({
    required super.type,
    required this.action,
    super.rawJson,
  });

  factory GenUiFollowUpActionModel.fromJson(Map<String, dynamic> json) {
    return GenUiFollowUpActionModel(
      type: json['type']?.toString() ?? 'follow_up_question',
      action: GenUiFollowUpAction.fromJson(json),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, action];
}

/// Fallback model for unrecognized JSON widget components.
final class GenUiFallbackModel extends GenUiComponentModel {
  final String unknownType;
  final String message;

  const GenUiFallbackModel({
    required super.type,
    required this.unknownType,
    required this.message,
    super.rawJson,
  });

  factory GenUiFallbackModel.fromJson(Map<String, dynamic> json) {
    return GenUiFallbackModel(
      type: 'fallback_card',
      unknownType: json['type']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? 'Custom dynamic content',
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, unknownType, message];
}

/// Interactive medication intake card model supporting 1-tap taken confirmation and reminder scheduling.
final class GenUiMedicationIntakeModel extends GenUiComponentModel {
  final String medicationName;
  final String dosage;
  final String scheduledTime;
  final String? instructions;
  final String status; // 'pending', 'taken', 'snoozed'
  final String? frequency;

  const GenUiMedicationIntakeModel({
    required super.type,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    this.instructions,
    this.status = 'pending',
    this.frequency,
    super.rawJson,
  });

  factory GenUiMedicationIntakeModel.fromJson(Map<String, dynamic> json) {
    return GenUiMedicationIntakeModel(
      type: json['type']?.toString() ?? 'medication_intake_card',
      medicationName: json['medicationName']?.toString() ??
          json['medication']?.toString() ??
          json['name']?.toString() ??
          'Medication',
      dosage: json['dosage']?.toString() ?? '',
      scheduledTime: json['scheduledTime']?.toString() ??
          json['time']?.toString() ??
          'Today',
      instructions: json['instructions']?.toString() ?? json['notes']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      frequency: json['frequency']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props =>
      [type, medicationName, dosage, scheduledTime, instructions, status, frequency];
}

/// Single lab analyte model with reference range and status classification.
class LabAnalyte extends Equatable {
  final String name;
  final String value;
  final String unit;
  final String referenceRange;
  final String status; // 'normal', 'borderline', 'high', 'low'

  const LabAnalyte({
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
  });

  factory LabAnalyte.fromJson(Map<String, dynamic> json) {
    return LabAnalyte(
      name: json['name']?.toString() ?? json['analyte']?.toString() ?? 'Test',
      value: json['value']?.toString() ?? '--',
      unit: json['unit']?.toString() ?? '',
      referenceRange: json['referenceRange']?.toString() ?? json['range']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'normal',
    );
  }

  @override
  List<Object?> get props => [name, value, unit, referenceRange, status];
}

/// Lab panel result model with individual analytes and PDF export capability.
final class GenUiLabResultsModel extends GenUiComponentModel {
  final String panelName;
  final String collectionDate;
  final String? labProvider;
  final List<LabAnalyte> analytes;
  final String? clinicalNote;

  const GenUiLabResultsModel({
    required super.type,
    required this.panelName,
    required this.collectionDate,
    this.labProvider,
    required this.analytes,
    this.clinicalNote,
    super.rawJson,
  });

  factory GenUiLabResultsModel.fromJson(Map<String, dynamic> json) {
    final rawAnalytes = json['analytes'] as List? ?? json['results'] as List? ?? [];
    return GenUiLabResultsModel(
      type: json['type']?.toString() ?? 'lab_results_card',
      panelName: json['panelName']?.toString() ?? json['title']?.toString() ?? 'Lab Test Results',
      collectionDate: json['collectionDate']?.toString() ?? json['date']?.toString() ?? 'Recent',
      labProvider: json['labProvider']?.toString() ?? json['lab']?.toString(),
      analytes: rawAnalytes
          .whereType<Map<String, dynamic>>()
          .map((a) => LabAnalyte.fromJson(a))
          .toList(),
      clinicalNote: json['clinicalNote']?.toString() ?? json['summary']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props =>
      [type, panelName, collectionDate, labProvider, analytes, clinicalNote];
}

/// Clinical health risk gauge model with score, risk level, and contributing factors.
final class GenUiRiskGaugeModel extends GenUiComponentModel {
  final String title;
  final double scorePercentage;
  final String riskLevel; // 'low', 'moderate', 'high', 'critical'
  final String categoryDescription;
  final List<String> contributingFactors;
  final String recommendation;

  const GenUiRiskGaugeModel({
    required super.type,
    required this.title,
    required this.scorePercentage,
    required this.riskLevel,
    required this.categoryDescription,
    required this.contributingFactors,
    required this.recommendation,
    super.rawJson,
  });

  factory GenUiRiskGaugeModel.fromJson(Map<String, dynamic> json) {
    final factors = json['contributingFactors'] as List? ?? json['factors'] as List? ?? [];
    return GenUiRiskGaugeModel(
      type: json['type']?.toString() ?? 'risk_gauge_card',
      title: json['title']?.toString() ?? 'Clinical Risk Assessment',
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          10.0,
      riskLevel: json['riskLevel']?.toString().toLowerCase() ?? 'low',
      categoryDescription: json['categoryDescription']?.toString() ??
          json['description']?.toString() ??
          '',
      contributingFactors: factors.map((e) => e.toString()).toList(),
      recommendation: json['recommendation']?.toString() ?? '',
      rawJson: json,
    );
  }

  @override
  List<Object?> get props =>
      [type, title, scorePercentage, riskLevel, categoryDescription, contributingFactors, recommendation];
}

/// Interactive checklist item for medical consultations.
class ChecklistItem extends Equatable {
  final String question;
  final String? category;
  final bool isChecked;

  const ChecklistItem({
    required this.question,
    this.category,
    this.isChecked = false,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      question: json['question']?.toString() ?? json['item']?.toString() ?? '',
      category: json['category']?.toString(),
      isChecked: json['isChecked'] == true || json['checked'] == true,
    );
  }

  ChecklistItem copyWith({bool? isChecked}) {
    return ChecklistItem(
      question: question,
      category: category,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  List<Object?> get props => [question, category, isChecked];
}

/// Doctor consultation discussion checklist model with checkable items and PDF export.
final class GenUiDoctorChecklistModel extends GenUiComponentModel {
  final String title;
  final String appointmentFocus;
  final List<ChecklistItem> checklistItems;
  final String? doctorNotesPlaceholder;

  const GenUiDoctorChecklistModel({
    required super.type,
    required this.title,
    required this.appointmentFocus,
    required this.checklistItems,
    this.doctorNotesPlaceholder,
    super.rawJson,
  });

  factory GenUiDoctorChecklistModel.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['checklistItems'] as List? ?? json['items'] as List? ?? json['questions'] as List? ?? [];
    return GenUiDoctorChecklistModel(
      type: json['type']?.toString() ?? 'doctor_checklist_card',
      title: json['title']?.toString() ?? 'Doctor Visit Discussion Guide',
      appointmentFocus: json['appointmentFocus']?.toString() ??
          json['focus']?.toString() ??
          'Upcoming Medical Consultation',
      checklistItems: rawItems.map((item) {
        if (item is Map<String, dynamic>) {
          return ChecklistItem.fromJson(item);
        }
        return ChecklistItem(question: item.toString());
      }).toList(),
      doctorNotesPlaceholder: json['doctorNotesPlaceholder']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props =>
      [type, title, appointmentFocus, checklistItems, doctorNotesPlaceholder];
}

/// Strongly typed schema model representing full AI response payload with intent, evidence, components, and verified actions.
class GenUiStructuredResponse extends Equatable {
  final String intent;
  final String answer;
  final String? uncertaintyNote;
  final String? evidenceSource;
  final List<GenUiComponentModel> components;
  final List<GenUiActionButtonModel> actions;
  final List<GenUiFollowUpAction> followUps;
  final String? safetyNotice;

  const GenUiStructuredResponse({
    required this.intent,
    required this.answer,
    this.uncertaintyNote,
    this.evidenceSource,
    this.components = const [],
    this.actions = const [],
    this.followUps = const [],
    this.safetyNotice,
  });

  @override
  List<Object?> get props => [
        intent,
        answer,
        uncertaintyNote,
        evidenceSource,
        components,
        actions,
        followUps,
        safetyNotice,
      ];
}

