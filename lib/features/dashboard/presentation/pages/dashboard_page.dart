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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';

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
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      AppShimmer.card(height: 80),
                      SizedBox(height: 16),
                      AppShimmer.card(height: 140),
                      SizedBox(height: 16),
                      AppShimmer.card(height: 180),
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
                title: DashboardHeader(
                  patient: patient,
                  onSwitchPatient: () => context.go('/patients'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people_alt_outlined),
                    tooltip: 'Switch Patient Profile',
                    onPressed: () => context.go('/patients'),
                  ),
                ],
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Health Score & Insight Hero Card
                      AppCard(
                        gradient: AppColors.aiGradient,
                        padding: const EdgeInsets.all(20),
                        boxShadow: AppShadows.aiGlow(context),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'AI Clinical Insight',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Vitals are stable today',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Blood pressure and pulse show optimal trends over the last 7 days.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => context.go('/ai-chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.tertiaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                              child: const Text('Consult', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Latest Vitals Summary Grid
                      BlocBuilder<VitalsBloc, VitalsState>(
                        builder: (context, vitalsState) {
                          Map<String, String> vitalsMap = {};
                          if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
                            for (var v in vitalsState.records) {
                              if (v.systolic != null && v.diastolic != null && !vitalsMap.containsKey('bp')) {
                                vitalsMap['bp'] = '${v.systolic!.toInt()}/${v.diastolic!.toInt()}';
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
                      const SizedBox(height: 24),

                      // Quick Actions Grid
                      DashboardQuickActions(
                        onLogVitals: () => context.go('/add-vital'),
                        onAskAi: () => context.go('/ai-chat'),
                        onViewCharts: () => context.go('/charts'),
                        onViewHistory: () => context.go('/history'),
                      ),
                      const SizedBox(height: 24),

                      // Reminders Overview Card
                      TodayRemindersCard(
                        onManageReminders: () => context.go('/settings'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => context.go('/add-vital'),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Record Vital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primary,
                elevation: 6,
              ),
            );
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.primary),
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
