import 'package:equatable/equatable.dart';

/// Base abstract class for all Generative UI component models parsed from AI structured JSON.
abstract class GenUiComponentModel extends Equatable {
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
class GenUiMetricSummaryModel extends GenUiComponentModel {
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
class GenUiTrendChartModel extends GenUiComponentModel {
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
class GenUiComparisonChartModel extends GenUiComponentModel {
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
class GenUiEducationCardModel extends GenUiComponentModel {
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
class GenUiRecommendationCardModel extends GenUiComponentModel {
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
class GenUiReportCardModel extends GenUiComponentModel {
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
class GenUiTimelineCardModel extends GenUiComponentModel {
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
class GenUiReminderCardModel extends GenUiComponentModel {
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
class GenUiAiInsightCardModel extends GenUiComponentModel {
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
class GenUiPatientProfileCardModel extends GenUiComponentModel {
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

/// Action Button component model.
class GenUiActionButtonModel extends GenUiComponentModel {
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

  factory GenUiActionButtonModel.fromJson(Map<String, dynamic> json) {
    return GenUiActionButtonModel(
      type: json['type']?.toString() ?? 'action_button',
      label: json['label']?.toString() ?? json['text']?.toString() ?? 'Action',
      action: json['action']?.toString() ?? 'navigate',
      route: json['route']?.toString(),
      rawJson: json,
    );
  }

  @override
  List<Object?> get props => [type, label, action, route];
}

/// Fallback model for unrecognized JSON widget components.
class GenUiFallbackModel extends GenUiComponentModel {
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
