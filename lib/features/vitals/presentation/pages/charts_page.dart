import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';
import '../../data/models/vital_record.dart';

/// Screen visualizing logged vital readings trends using fl_chart.
class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _rangeDays = 7; // 7 or 30 days
  String _activeTab = 'bp'; // 'bp', 'glucose', 'pulse', 'temp', 'weight'

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
            body: Center(child: Text("Please select a patient profile first.")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Health Trends'),
            actions: [
              // Range toggles (7D / 30D)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7D')),
                    ButtonSegment(value: 30, label: Text('30D')),
                  ],
                  selected: {_rangeDays},
                  onSelectionChanged: (val) {
                    setState(() => _rangeDays = val.first);
                    _loadVitals();
                  },
                ),
              ),
            ],
          ),
          body: BlocBuilder<VitalsBloc, VitalsState>(
            builder: (context, vitalsState) {
              if (vitalsState is VitalsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vitalsState is VitalsLoadSuccess) {
                final records = vitalsState.records.reversed.toList(); // Chronological

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Metric Switcher Chips
                      _buildMetricSelector(theme),
                      const SizedBox(height: 24),

                      // Chart Card Panel
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getChartTitle(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 260,
                                child: records.isEmpty
                                    ? const Center(child: Text('No data recorded in this range.'))
                                    : LineChart(_buildChartData(records, theme)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector(ThemeData theme) {
    final chips = [
      {'id': 'bp', 'label': 'Blood Pressure', 'icon': Icons.favorite_outline},
      {'id': 'glucose', 'label': 'Glucose', 'icon': Icons.opacity},
      {'id': 'pulse', 'label': 'Pulse Rate', 'icon': Icons.heart_broken_outlined},
      {'id': 'temp', 'label': 'Temperature', 'icon': Icons.thermostat},
      {'id': 'weight', 'label': 'Weight', 'icon': Icons.scale_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) {
          final isSelected = _activeTab == chip['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              iconTheme: IconThemeData(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
              label: Text(chip['label'] as String),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _activeTab = chip['id'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getChartTitle() {
    switch (_activeTab) {
      case 'bp':
        return 'Blood Pressure History';
      case 'glucose':
        return 'Blood Glucose Trends';
      case 'pulse':
        return 'Heart Rate (BPM)';
      case 'temp':
        return 'Body Temperature';
      case 'weight':
        return 'Weight Progress & BMI';
      default:
        return 'Health Trends';
    }
  }

  LineChartData _buildChartData(List<VitalRecord> records, ThemeData theme) {
    final List<FlSpot> spots1 = [];
    final List<FlSpot> spots2 = []; // Used for diastolic in BP

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final double xVal = i.toDouble();

      if (_activeTab == 'bp' && r.systolic != null && r.diastolic != null) {
        spots1.add(FlSpot(xVal, r.systolic!));
        spots2.add(FlSpot(xVal, r.diastolic!));
      } else if (_activeTab == 'glucose' && r.glucoseValue != null) {
        spots1.add(FlSpot(xVal, r.glucoseValue!));
      } else if (_activeTab == 'pulse' && r.pulseRate != null) {
        spots1.add(FlSpot(xVal, r.pulseRate!));
      } else if (_activeTab == 'temp' && r.bodyTemperature != null) {
        spots1.add(FlSpot(xVal, r.bodyTemperature!));
      } else if (_activeTab == 'weight' && r.weight != null) {
        spots1.add(FlSpot(xVal, r.weight!));
      }
    }

    final List<LineChartBarData> lineBars = [];

    if (spots1.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: spots1,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
      );
    }

    if (_activeTab == 'bp' && spots2.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: spots2,
          isCurved: true,
          color: theme.colorScheme.tertiary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.tertiary.withOpacity(0.1),
          ),
        ),
      );
    }

    return LineChartData(
      lineBarsData: lineBars,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
      ),
    );
  }
}
