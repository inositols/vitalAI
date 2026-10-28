import 'package:flutter/material.dart';
import '../models/genui_component_model.dart';
import '../widgets/blood_pressure_card_widget.dart';
import '../widgets/glucose_card_widget.dart';
import '../widgets/pulse_card_widget.dart';
import '../widgets/temperature_card_widget.dart';
import '../widgets/weight_card_widget.dart';
import '../widgets/spo2_card_widget.dart';
import '../widgets/health_summary_card_widget.dart';
import '../widgets/genui_trend_chart_widget.dart';
import '../widgets/comparison_chart_widget.dart';
import '../widgets/education_card_widget.dart';
import '../widgets/recommendation_card_widget.dart';
import '../widgets/report_card_widget.dart';
import '../widgets/timeline_card_widget.dart';
import '../widgets/reminder_card_widget.dart';
import '../widgets/ai_insight_card_widget.dart';
import '../widgets/patient_profile_card_widget.dart';
import '../widgets/genui_action_button.dart';
import '../widgets/genui_educational_tip.dart';
import '../widgets/genui_metric_summary_card.dart';
import '../widgets/fallback_card_widget.dart';
import '../widgets/genui_follow_up_suggestions_widget.dart';
import '../widgets/medication_intake_card_widget.dart';
import '../widgets/lab_results_card_widget.dart';
import '../widgets/risk_gauge_card_widget.dart';
import '../widgets/doctor_checklist_card_widget.dart';

typedef GenUiWidgetBuilderFunction = Widget Function(BuildContext context, GenUiComponentModel model);

/// Widget Registry mapping dynamic JSON string identifiers to reusable Flutter widgets.
class WidgetRegistry {
  static final WidgetRegistry _instance = WidgetRegistry._internal();
  factory WidgetRegistry() => _instance;
  WidgetRegistry._internal() {
    _registerDefaults();
  }

  final Map<String, GenUiWidgetBuilderFunction> _registry = {};

  /// Register a new widget identifier and builder function.
  void register(String identifier, GenUiWidgetBuilderFunction builder) {
    _registry[identifier.toLowerCase().trim()] = builder;
  }

  /// Resolve and build widget for a component model using Dart 3 exhaustive pattern matching.
  Widget buildWidget(BuildContext context, GenUiComponentModel model) {
    // 1. Dynamic registry override if registered explicitly
    final customBuilder = _registry[model.type.toLowerCase().trim()];
    if (customBuilder != null) {
      return customBuilder(context, model);
    }

    // 2. Exhaustive Dart 3 sealed pattern matching
    return switch (model) {
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'bp' || m.type == 'blood_pressure_card' =>
        BloodPressureCardWidget(model: m),
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'glucose' || m.type == 'glucose_card' =>
        GlucoseCardWidget(model: m),
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'pulse' || m.type == 'pulse_card' =>
        PulseCardWidget(model: m),
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'temp' ||
              m.metricType?.toLowerCase() == 'temperature' ||
              m.type == 'temperature_card' =>
        TemperatureCardWidget(model: m),
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'weight' || m.type == 'weight_card' =>
        WeightCardWidget(model: m),
      GenUiMetricSummaryModel m
          when m.metricType?.toLowerCase() == 'spo2' || m.type == 'spo2_card' =>
        Spo2CardWidget(model: m),
      GenUiMetricSummaryModel m when m.type == 'health_summary_card' =>
        HealthSummaryCardWidget(model: m),
      GenUiMetricSummaryModel m => GenUiMetricSummaryCard(model: m),
      GenUiTrendChartModel m => GenUiTrendChartWidget(model: m),
      GenUiComparisonChartModel m => ComparisonChartWidget(model: m),
      GenUiMedicationIntakeModel m => MedicationIntakeCardWidget(model: m),
      GenUiLabResultsModel m => LabResultsCardWidget(model: m),
      GenUiRiskGaugeModel m => RiskGaugeCardWidget(model: m),
      GenUiDoctorChecklistModel m => DoctorChecklistCardWidget(model: m),
      GenUiEducationCardModel m => EducationCardWidget(model: m),
      GenUiRecommendationCardModel m => RecommendationCardWidget(model: m),
      GenUiReportCardModel m => ReportCardWidget(model: m),
      GenUiTimelineCardModel m => TimelineCardWidget(model: m),
      GenUiReminderCardModel m => ReminderCardWidget(model: m),
      GenUiAiInsightCardModel m => AiInsightCardWidget(model: m),
      GenUiPatientProfileCardModel m => PatientProfileCardWidget(model: m),
      GenUiActionButtonModel m => GenUiActionButtonWidget(model: m),
      GenUiFollowUpSuggestionsModel m => GenUiFollowUpSuggestionsWidget(model: m),
      GenUiFollowUpActionModel m => GenUiFollowUpSuggestionsWidget(model: m),
      GenUiFallbackModel m => FallbackCardWidget(model: m),
    };
  }

  void _registerDefaults() {
    register('blood_pressure_card', (ctx, m) => BloodPressureCardWidget(model: m as GenUiMetricSummaryModel));
    register('glucose_card', (ctx, m) => GlucoseCardWidget(model: m as GenUiMetricSummaryModel));
    register('pulse_card', (ctx, m) => PulseCardWidget(model: m as GenUiMetricSummaryModel));
    register('temperature_card', (ctx, m) => TemperatureCardWidget(model: m as GenUiMetricSummaryModel));
    register('weight_card', (ctx, m) => WeightCardWidget(model: m as GenUiMetricSummaryModel));
    register('spo2_card', (ctx, m) => Spo2CardWidget(model: m as GenUiMetricSummaryModel));
    register('health_summary_card', (ctx, m) => HealthSummaryCardWidget(model: m as GenUiMetricSummaryModel));
    register('metric_summary', (ctx, m) => GenUiMetricSummaryCard(model: m as GenUiMetricSummaryModel));
    register('trend_chart', (ctx, m) => GenUiTrendChartWidget(model: m as GenUiTrendChartModel));
    register('comparison_chart', (ctx, m) => ComparisonChartWidget(model: m as GenUiComparisonChartModel));
    register('education_card', (ctx, m) => EducationCardWidget(model: m as GenUiEducationCardModel));
    register('educational_tip', (ctx, m) => GenUiEducationalTipWidget(model: m as GenUiEducationCardModel));
    register('recommendation_card', (ctx, m) => RecommendationCardWidget(model: m as GenUiRecommendationCardModel));
    register('report_card', (ctx, m) => ReportCardWidget(model: m as GenUiReportCardModel));
    register('timeline_card', (ctx, m) => TimelineCardWidget(model: m as GenUiTimelineCardModel));
    register('reminder_card', (ctx, m) => ReminderCardWidget(model: m as GenUiReminderCardModel));
    register('medication_card', (ctx, m) => ReminderCardWidget(model: m as GenUiReminderCardModel));
    register('medication_intake_card', (ctx, m) => MedicationIntakeCardWidget(model: m as GenUiMedicationIntakeModel));
    register('medication_intake', (ctx, m) => MedicationIntakeCardWidget(model: m as GenUiMedicationIntakeModel));
    register('pill_reminder', (ctx, m) => MedicationIntakeCardWidget(model: m as GenUiMedicationIntakeModel));
    register('lab_results_card', (ctx, m) => LabResultsCardWidget(model: m as GenUiLabResultsModel));
    register('lab_results', (ctx, m) => LabResultsCardWidget(model: m as GenUiLabResultsModel));
    register('lab_panel', (ctx, m) => LabResultsCardWidget(model: m as GenUiLabResultsModel));
    register('risk_gauge_card', (ctx, m) => RiskGaugeCardWidget(model: m as GenUiRiskGaugeModel));
    register('risk_gauge', (ctx, m) => RiskGaugeCardWidget(model: m as GenUiRiskGaugeModel));
    register('health_risk_gauge', (ctx, m) => RiskGaugeCardWidget(model: m as GenUiRiskGaugeModel));
    register('doctor_checklist_card', (ctx, m) => DoctorChecklistCardWidget(model: m as GenUiDoctorChecklistModel));
    register('doctor_checklist', (ctx, m) => DoctorChecklistCardWidget(model: m as GenUiDoctorChecklistModel));
    register('visit_checklist', (ctx, m) => DoctorChecklistCardWidget(model: m as GenUiDoctorChecklistModel));
    register('ai_insight_card', (ctx, m) => AiInsightCardWidget(model: m as GenUiAiInsightCardModel));
    register('patient_profile_card', (ctx, m) => PatientProfileCardWidget(model: m as GenUiPatientProfileCardModel));
    register('action_button', (ctx, m) => GenUiActionButtonWidget(model: m as GenUiActionButtonModel));
    register('follow_up_suggestions', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('suggested_actions', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('follow_ups', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('follow_up_question', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('navigation', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('view_vital', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('data_action', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
    register('information_expansion', (ctx, m) => GenUiFollowUpSuggestionsWidget(model: m));
  }
}

