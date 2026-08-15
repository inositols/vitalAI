import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../../core/di/injection.dart';
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
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Clean Native Apple Health Header
                      DashboardHeader(
                        patient: patient,
                        onSwitchPatient: () => context.go('/patients'),
                        onLogVital: () => context.go('/add-vital'),
                      ),
                      const SizedBox(height: 16),

                      // 2. Warm Human Health Snapshot
                      AiInsightCard(
                        onAskAi: () => context.go('/ai-chat'),
                      ),
                      const SizedBox(height: 20),

                      // 3. Favorites / Today's Vitals Grid
                      BlocBuilder<VitalsBloc, VitalsState>(
                        builder: (context, vitalsState) {
                          Map<String, String> vitalsMap = {};
                          if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
                            for (var v in vitalsState.records) {
                              if (v.systolic != null && v.diastolic != null && !vitalsMap.containsKey('bp')) {
                                vitalsMap['bp'] = '${v.systolic!.toInt()}/${v.diastolic!.toInt()}';
                              }
                              if (v.glucoseValue != null && !vitalsMap.containsKey('glucose')) {
                                vitalsMap['glucose'] = '${v.glucoseValue!.toInt()}';
                              }
                              if (v.pulseRate != null && !vitalsMap.containsKey('pulse')) {
                                vitalsMap['pulse'] = '${v.pulseRate!.toInt()}';
                              }
                              if (v.oxygenSaturation != null && !vitalsMap.containsKey('spo2')) {
                                vitalsMap['spo2'] = '${v.oxygenSaturation!.toInt()}';
                              }
                            }
                          }

                          return VitalsSummaryGrid(
                            latestVitals: vitalsMap,
                            onMetricTap: (type) => context.go('/charts'),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 4. Today's Schedule & Reminders
                      TodayRemindersCard(
                        onManageReminders: () => context.go('/reminders'),
                      ),
                      const SizedBox(height: 24),
                    ],
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
