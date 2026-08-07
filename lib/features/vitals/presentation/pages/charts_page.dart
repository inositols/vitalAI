import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';
import '../widgets/health_line_chart.dart';
import '../widgets/vital_metric_selector.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _rangeDays = 7;
  String _activeTab = 'bp';

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  void _loadVitals() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      final now = DateTime.now();
      final rawStart = now.subtract(Duration(days: _rangeDays));
      final start = DateTime(rawStart.year, rawStart.month, rawStart.day, 0, 0, 0);
      context.read<VitalsBloc>().add(
            VitalsFilteredRequested(
              patientId: patientState.activePatient!.id,
              startDate: start,
              endDate: now,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocConsumer<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientLoadSuccess && state.activePatient != null) {
          _loadVitals();
        }
      },
      builder: (context, patientState) {
        if (patientState is PatientLoading) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AppShimmer.card(height: 60),
                    SizedBox(height: 16),
                    AppShimmer.card(height: 280),
                  ],
                ),
              ),
            ),
          );
        }

        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: AppEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No Active Patient Profile',
              message: 'Please select a patient profile to view historical vital charts.',
            ),
          );
        }

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const AppBrandLogo(
                  size: 28,
                  iconSize: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Health Trends & Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Patient: ${patient.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'View Full Log History',
                onPressed: () => context.go('/history'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range Segment Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Frame',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7 Days', style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: 30, label: Text('30 Days', style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_rangeDays},
                        onSelectionChanged: (val) {
                          setState(() {
                            _rangeDays = val.first;
                            _loadVitals();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vital Metric Selector Chips
                  VitalMetricSelector(
                    activeTab: _activeTab,
                    onSelectTab: (tab) => setState(() => _activeTab = tab),
                  ),
                  const SizedBox(height: 20),

                  // Interactive Chart View
                  BlocBuilder<VitalsBloc, VitalsState>(
                    builder: (context, vitalsState) {
                      if (vitalsState is VitalsLoading) {
                        return const AppShimmer.card(height: 320);
                      }

                      if (vitalsState is VitalsLoadSuccess) {
                        if (vitalsState.records.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.show_chart_rounded,
                            title: 'No Data for Selected Period',
                            message: 'Record vitals in the Add Vital tab to generate analytical trend charts.',
                          );
                        }
                        return HealthLineChart(
                          activeTab: _activeTab,
                          records: vitalsState.records,
                        );
                      }

                      return const AppEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to Load Trends',
                        message: 'Error fetching vitals chart data.',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
