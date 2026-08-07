import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/genui/genui_renderer.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_shimmer.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/vitals_summary_grid.dart';
import '../widgets/today_reminders_card.dart';

import '../../../reminders/presentation/bloc/reminders_bloc.dart';
import '../../../reminders/presentation/bloc/reminders_event.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
    locator<NotificationService>().requestPermissions();
  }

  void _loadData() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      final pid = patientState.activePatient!.id;
      context.read<VitalsBloc>().add(VitalsListRequested(pid));
      context.read<RemindersBloc>().add(RemindersListRequested(pid));
    }
  }

  String? _generateSmartGenUiContent(VitalsState state) {
    if (state is! VitalsLoadSuccess || state.records.isEmpty) return null;

    final latestBp = state.records.firstWhere((r) => r.systolic != null, orElse: () => state.records.first);
    final latestGlucose = state.records.firstWhere((r) => r.glucoseValue != null, orElse: () => state.records.first);

    // If blood pressure is elevated
    if (latestBp.systolic != null && latestBp.systolic! >= 130) {
      return '''
Smart Focus: Elevated Blood Pressure Priority View

```json
{
  "type": "blood_pressure_card",
  "title": "Elevated Blood Pressure Focus",
  "value": "${latestBp.systolic!.toInt()}/${latestBp.diastolic?.toInt() ?? 85}",
  "unit": "mmHg",
  "status": "elevated",
  "subtitle": "Last reading is above target 120/80 mmHg"
}
```

```json
{
  "type": "recommendation_card",
  "title": "Hypertension Action Protocol",
  "priority": "high",
  "reason": "Elevated systolic pressure detected. Reducing daily sodium intake and engaging in light 20-minute aerobic walk daily supports vascular recovery.",
  "relatedMetric": "Blood Pressure",
  "suggestedFollowUp": [
    "Log evening resting blood pressure",
    "Limit sodium to under 2,000 mg today"
  ],
  "disclaimer": "Educational tracking recommendation only. Consult your physician."
}
```

```json
{
  "type": "trend_chart",
  "title": "Systolic BP 7-Day Pattern",
  "metricType": "bp",
  "dataPoints": [134, 132, 130, 135, ${latestBp.systolic!.toInt()}],
  "labels": ["Day 1", "Day 2", "Day 3", "Day 4", "Today"]
}
```
''';
    }

    // If glucose is abnormal
    if (latestGlucose.glucoseValue != null && latestGlucose.glucoseValue! >= 120) {
      return '''
Smart Focus: Blood Glucose Priority View

```json
{
  "type": "glucose_card",
  "title": "Fasting Glucose Alert",
  "value": "${latestGlucose.glucoseValue!.toInt()}",
  "unit": "mg/dL",
  "status": "warning",
  "subtitle": "Fasting glucose elevated above 100 mg/dL target"
}
```

```json
{
  "type": "education_card",
  "title": "Post-Meal Glucose Management",
  "definition": "A 10-minute light walk after meals uses muscle glycogen stores, lowering glucose spikes without extra insulin demand.",
  "normalRange": "70 - 99 mg/dL (Fasting)"
}
```
''';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientLoadSuccess && state.activePatient != null) {
          final pid = state.activePatient!.id;
          context.read<VitalsBloc>().add(VitalsListRequested(pid));
          context.read<RemindersBloc>().add(RemindersListRequested(pid));
        }
      },
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      AppShimmer.card(height: 60),
                      SizedBox(height: 16),
                      AppShimmer.card(height: 120),
                      SizedBox(height: 16),
                      AppShimmer.card(height: 140),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is PatientLoadSuccess && state.activePatient != null) {
            final patient = state.activePatient!;

            return Scaffold(
              appBar: AppBar(
                titleSpacing: 16,
                title: DashboardHeader(
                  patient: patient,
                  onSwitchPatient: () => context.go('/patients'),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/add-vital'),
                      icon: const Icon(AppIcons.add, size: 16),
                      label: const Text('Log Vital', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: AppMotion.normal,
                  curve: AppMotion.easeInOutCubic,
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Executive AI Clinical Insight Banner
                        AiInsightCard(
                          onAskAi: () => context.go('/ai-chat'),
                        ),
                        const SizedBox(height: 18),

                        // 2. Dynamic Smart GenUI Priority Section (if elevated readings detected)
                        BlocBuilder<VitalsBloc, VitalsState>(
                          builder: (context, vitalsState) {
                            final genuiContent = _generateSmartGenUiContent(vitalsState);
                            if (genuiContent != null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GenUiRenderer(content: genuiContent),
                                  const SizedBox(height: 18),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // 3. Core Health Vitals Summary
                        BlocBuilder<VitalsBloc, VitalsState>(
                          builder: (context, vitalsState) {
                            Map<String, String> vitalsMap = {};
                            if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
                              for (var v in vitalsState.records) {
                                if (v.systolic != null && v.diastolic != null && !vitalsMap.containsKey('bp')) {
                                  vitalsMap['bp'] = '${v.systolic!.toInt()}/${v.diastolic!.toInt()} mmHg';
                                }
                                if (v.glucoseValue != null && !vitalsMap.containsKey('glucose')) {
                                  vitalsMap['glucose'] = '${v.glucoseValue!.toInt()} mg/dL';
                                }
                                if (v.pulseRate != null && !vitalsMap.containsKey('pulse')) {
                                  vitalsMap['pulse'] = '${v.pulseRate!.toInt()} bpm';
                                }
                              }
                            }

                            return VitalsSummaryGrid(
                              latestVitals: vitalsMap,
                              onAddVital: () => context.go('/add-vital'),
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        // 4. Today's Reminders Card
                        TodayRemindersCard(
                          onManageReminders: () => context.go('/reminders'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.patients, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('No Patient Profile Selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Please select or add a patient profile to continue'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/patients'),
                    child: const Text('Select Patient Profile'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
