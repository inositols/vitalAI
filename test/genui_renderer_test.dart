import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/genui/genui_renderer.dart';
import 'package:vitalai/core/genui/widgets/blood_pressure_card_widget.dart';
import 'package:vitalai/core/genui/widgets/glucose_card_widget.dart';
import 'package:vitalai/core/genui/widgets/education_card_widget.dart';
import 'package:vitalai/core/genui/widgets/recommendation_card_widget.dart';
import 'package:vitalai/core/genui/widgets/report_card_widget.dart';
import 'package:vitalai/core/genui/widgets/timeline_card_widget.dart';
import 'package:vitalai/core/genui/widgets/fallback_card_widget.dart';

void main() {
  group('GenUiRenderer Widget Tests', () {
    testWidgets('Renders natural text and interactive GenUI component cards correctly', (WidgetTester tester) async {
      const rawAiResponse = '''
Here is your complete health evaluation.

```json
{
  "type": "blood_pressure_card",
  "title": "Blood Pressure",
  "value": "120/80",
  "unit": "mmHg",
  "status": "normal"
}
```

```json
{
  "type": "glucose_card",
  "title": "Fasting Glucose",
  "value": "95",
  "unit": "mg/dL",
  "status": "normal"
}
```

```json
{
  "type": "education_card",
  "title": "Systolic Pressure",
  "definition": "Pressure during heart ventricle contraction."
}
```

```json
{
  "type": "recommendation_card",
  "title": "Hydration Plan",
  "priority": "high",
  "reason": "Maintains optimal blood volume.",
  "disclaimer": "Educational tracking only."
}
```

Keep tracking daily!
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GenUiRenderer(content: rawAiResponse),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify text
      expect(find.textContaining('Here is your complete health evaluation.'), findsOneWidget);
      expect(find.textContaining('Keep tracking daily!'), findsOneWidget);
      expect(find.textContaining('```json'), findsNothing);

      // Verify components rendered
      expect(find.byType(BloodPressureCardWidget), findsOneWidget);
      expect(find.text('120/80'), findsOneWidget);

      expect(find.byType(GlucoseCardWidget), findsOneWidget);
      expect(find.text('95'), findsOneWidget);

      expect(find.byType(EducationCardWidget), findsOneWidget);
      expect(find.text('Systolic Pressure'), findsOneWidget);

      expect(find.byType(RecommendationCardWidget), findsOneWidget);
      expect(find.text('Hydration Plan'), findsOneWidget);
    });

    testWidgets('Renders ReportCardWidget and TimelineCardWidget correctly', (WidgetTester tester) async {
      const rawResponse = '''
```json
{
  "type": "report_card",
  "patientName": "John Doe",
  "reportDate": "August 2026",
  "summaryText": "Vitals within normal limits."
}
```

```json
{
  "type": "timeline_card",
  "title": "Health Progression",
  "timeSpan": "Last 6 Months",
  "monthlyEvents": [
    {"month": "May 2026", "note": "BP 120/80 mmHg"}
  ],
  "highlights": ["Consistent blood pressure"]
}
```
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GenUiRenderer(content: rawResponse),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ReportCardWidget), findsOneWidget);
      expect(find.textContaining('John Doe'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);

      expect(find.byType(TimelineCardWidget), findsOneWidget);
      expect(find.text('Health Progression'), findsOneWidget);
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('Gracefully handles unknown component type with FallbackCardWidget', (WidgetTester tester) async {
      const rawResponse = '''
```json
{
  "type": "unknown_future_widget",
  "message": "Custom experimental widget"
}
```
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenUiRenderer(content: rawResponse),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FallbackCardWidget), findsOneWidget);
      expect(find.textContaining('Custom Component (unknown_future_widget)'), findsOneWidget);
    });
  });
}
