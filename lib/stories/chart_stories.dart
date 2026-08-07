import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/genui/models/genui_component_model.dart';
import '../core/genui/widgets/genui_trend_chart_widget.dart';
import '../features/vitals/data/models/vital_record.dart';
import '../features/vitals/presentation/widgets/health_line_chart.dart';

WidgetbookFolder get chartStories {
  return WidgetbookFolder(
    name: 'Charts',
    children: [
      WidgetbookComponent(
        name: 'HealthLineChart',
        useCases: [
          WidgetbookUseCase(
            name: 'Blood Pressure Trend Chart',
            builder: (context) {
              final mockRecords = [
                VitalRecord()
                  ..id = 1
                  ..dateTime = DateTime.now().subtract(const Duration(days: 4))
                  ..systolic = 120
                  ..diastolic = 80,
                VitalRecord()
                  ..id = 2
                  ..dateTime = DateTime.now().subtract(const Duration(days: 3))
                  ..systolic = 124
                  ..diastolic = 82,
                VitalRecord()
                  ..id = 3
                  ..dateTime = DateTime.now().subtract(const Duration(days: 2))
                  ..systolic = 118
                  ..diastolic = 78,
                VitalRecord()
                  ..id = 4
                  ..dateTime = DateTime.now().subtract(const Duration(days: 1))
                  ..systolic = 122
                  ..diastolic = 81,
              ];

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HealthLineChart(
                    activeTab: 'bp',
                    records: mockRecords,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'GenUiTrendChartWidget',
        useCases: [
          WidgetbookUseCase(
            name: 'Inline AI GenUI Trend Chart',
            builder: (context) {
              const model = GenUiTrendChartModel(
                type: 'trend_chart',
                title: 'Weekly Glucose Summary',
                metricType: 'glucose',
                dataPoints: [95, 98, 92, 105, 99],
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
              );

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GenUiTrendChartWidget(model: model),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
