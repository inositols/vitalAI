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

  /// Resolve and build widget for a component model.
  Widget buildWidget(BuildContext context, GenUiComponentModel model) {
    // 1. Specific metric check for metric summaries
    if (model is GenUiMetricSummaryModel) {
      final mType = (model.metricType ?? '').toLowerCase();
      if (mType == 'bp' || model.type == 'blood_pressure_card') {
        return BloodPressureCardWidget(model: model);
      } else if (mType == 'glucose' || model.type == 'glucose_card') {
        return GlucoseCardWidget(model: model);
      } else if (mType == 'pulse' || model.type == 'pulse_card') {
        return PulseCardWidget(model: model);
      } else if (mType == 'temp' || mType == 'temperature' || model.type == 'temperature_card') {
        return TemperatureCardWidget(model: model);
      } else if (mType == 'weight' || model.type == 'weight_card') {
        return WeightCardWidget(model: model);
      } else if (mType == 'spo2' || model.type == 'spo2_card') {
        return Spo2CardWidget(model: model);
      } else if (model.type == 'health_summary_card') {
        return HealthSummaryCardWidget(model: model);
      }
    }

    // 2. Registry key lookup
    final builder = _registry[model.type.toLowerCase().trim()];
    if (builder != null) {
      return builder(context, model);
    }

    // 3. Typed fallback mapping
    if (model is GenUiTrendChartModel) {
      return GenUiTrendChartWidget(model: model);
    } else if (model is GenUiComparisonChartModel) {
      return ComparisonChartWidget(model: model);
    } else if (model is GenUiEducationCardModel) {
      return EducationCardWidget(model: model);
    } else if (model is GenUiRecommendationCardModel) {
      return RecommendationCardWidget(model: model);
    } else if (model is GenUiReportCardModel) {
      return ReportCardWidget(model: model);
    } else if (model is GenUiTimelineCardModel) {
      return TimelineCardWidget(model: model);
    } else if (model is GenUiMetricSummaryModel) {
      return GenUiMetricSummaryCard(model: model);
    } else if (model is GenUiReminderCardModel) {
      return ReminderCardWidget(model: model);
    } else if (model is GenUiAiInsightCardModel) {
      return AiInsightCardWidget(model: model);
    } else if (model is GenUiPatientProfileCardModel) {
      return PatientProfileCardWidget(model: model);
    } else if (model is GenUiActionButtonModel) {
      return GenUiActionButtonWidget(model: model);
    } else if (model is GenUiFallbackModel) {
      return FallbackCardWidget(model: model);
    }

    return FallbackCardWidget(
      model: GenUiFallbackModel(
        type: 'fallback_card',
        unknownType: model.type,
        message: 'Unrecognized component layout',
      ),
    );
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
    register('ai_insight_card', (ctx, m) => AiInsightCardWidget(model: m as GenUiAiInsightCardModel));
    register('patient_profile_card', (ctx, m) => PatientProfileCardWidget(model: m as GenUiPatientProfileCardModel));
    register('action_button', (ctx, m) => GenUiActionButtonWidget(model: m as GenUiActionButtonModel));
  }
}
