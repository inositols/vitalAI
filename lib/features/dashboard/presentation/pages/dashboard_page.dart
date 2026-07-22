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

import '../widgets/dashboard_header.dart';
import '../widgets/vitals_summary_grid.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/today_reminders_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadVitals();
    locator<NotificationService>().requestPermissions();
  }

  void _loadVitals() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      context.read<VitalsBloc>().add(
        VitalsListRequested(patientState.activePatient!.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientLoadSuccess && state.activePatient != null) {
          context.read<VitalsBloc>().add(
            VitalsListRequested(state.activePatient!.id),
          );
        }
      },
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is PatientLoadSuccess && state.activePatient != null) {
            final patient = state.activePatient!;

            return Scaffold(
              appBar: AppBar(
                title: DashboardHeader(
                  patient: patient,
                  onSwitchPatient: () => context.go('/patients'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people_alt_outlined),
                    tooltip: 'Patient Profiles',
                    onPressed: () => context.go('/patients'),
                  ),
                ],
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Latest Vitals Summary Grid
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
                      const SizedBox(height: 20),

                      // Quick Actions Grid
                      DashboardQuickActions(
                        onLogVitals: () => context.go('/add-vital'),
                        onAskAi: () => context.go('/ai-chat'),
                        onViewCharts: () => context.go('/charts'),
                        onViewHistory: () => context.go('/history'),
                      ),
                      const SizedBox(height: 20),

                      // Reminders Overview Card
                      TodayRemindersCard(
                        onManageReminders: () => context.go('/settings'),
                      ),
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
                  const Text('No Patient Profile Selected'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/patients'),
                    child: const Text('Select Patient'),
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
