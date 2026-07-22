import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      final start = DateTime.now().subtract(Duration(days: _rangeDays));
      context.read<VitalsBloc>().add(
            VitalsFilteredRequested(
              patientId: patientState.activePatient!.id,
              startDate: start,
              endDate: DateTime.now(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: Center(child: Text('No patient selected')),
          );
        }

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('Health Trends & Charts'),
                Text(
                  'Patient: ${patient.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Range:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7 Days')),
                          ButtonSegment(value: 30, label: Text('30 Days')),
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: VitalMetricSelector(
                    activeTab: _activeTab,
                    onSelectTab: (tab) => setState(() => _activeTab = tab),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<VitalsBloc, VitalsState>(
                    builder: (context, vitalsState) {
                      if (vitalsState is VitalsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (vitalsState is VitalsLoadSuccess) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: HealthLineChart(
                            activeTab: _activeTab,
                            records: vitalsState.records,
                          ),
                        );
                      }

                      return const Center(child: Text('No vitals data available.'));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
