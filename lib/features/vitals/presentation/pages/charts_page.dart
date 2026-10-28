import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../data/models/vital_record.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';
import '../widgets/health_line_chart.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _selectedPeriod = 'Monthly'; // 'Daily', 'Weekly', 'Monthly'
  String _activeMetric = 'bp'; // 'bp', 'glucose', 'pulse', 'spo2', 'temp', 'weight'

  final List<Map<String, dynamic>> _metricTabs = const [
    {'id': 'bp', 'label': 'Blood Pressure', 'short': 'BP', 'icon': Icons.favorite_rounded, 'color': AppColors.bpVital},
    {'id': 'glucose', 'label': 'Glucose', 'short': 'Glucose', 'icon': Icons.water_drop_rounded, 'color': AppColors.glucoseVital},
    {'id': 'pulse', 'label': 'Pulse Rate', 'short': 'Pulse', 'icon': Icons.monitor_heart_rounded, 'color': AppColors.pulseVital},
    {'id': 'spo2', 'label': 'Oxygen (SpO₂)', 'short': 'SpO₂', 'icon': Icons.air_rounded, 'color': AppColors.spo2Vital},
    {'id': 'temp', 'label': 'Body Temp', 'short': 'Temp', 'icon': Icons.thermostat_rounded, 'color': AppColors.tempVital},
    {'id': 'weight', 'label': 'Weight & BMI', 'short': 'Weight', 'icon': Icons.scale_rounded, 'color': AppColors.weightVital},
  ];

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  void _loadVitals() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      context.read<VitalsBloc>().add(VitalsListRequested(patientState.activePatient!.id));
    }
  }

  List<VitalRecord> _filterRecordsByPeriod(List<VitalRecord> records) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedPeriod) {
      case 'Daily':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case 'Weekly':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
      default:
        cutoff = now.subtract(const Duration(days: 30));
        break;
    }

    final filtered = records.where((r) => r.dateTime.isAfter(cutoff)).toList();
    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;
        final patientName = (activePatient != null && activePatient.name.trim().isNotEmpty)
            ? activePatient.name.trim()
            : 'User';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          appBar: AppTopBar(
            title: 'Vitals & Analytics',
            initials: patientName,
            onAvatarTap: () => context.go('/settings'),
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
              tooltip: 'Full History',
              onPressed: () => context.push('/history'),
            ),
          ),
          body: SafeArea(
            child: BlocBuilder<VitalsBloc, VitalsState>(
              builder: (context, vitalsState) {
                final allRecords = vitalsState is VitalsLoadSuccess ? vitalsState.records : <VitalRecord>[];
                final filteredRecords = _filterRecordsByPeriod(allRecords);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Metric Category Horizontal Selector
                      _buildMetricSelector(isDark),
                      const SizedBox(height: 14),

                      // 2. Period Selector (Daily / Weekly / Monthly)
                      _buildPeriodSegmentedControl(isDark),
                      const SizedBox(height: 16),

                      // 3. Featured Chart with Real Data
                      _buildActiveChartCard(context, filteredRecords, isDark),
                      const SizedBox(height: 16),

                      // 4. Computed Statistics (Real averages, highs, lows, counts)
                      _buildComputedStatsGrid(filteredRecords, isDark),
                      const SizedBox(height: 20),

                      // 5. Recent Vital Snapshots Grid (All metrics)
                      _buildLatestVitalsOverview(allRecords, isDark),
                      const SizedBox(height: 24),

                      // 6. Action Button (+ Log Vitals)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/add-vital'),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.white),
                          label: const Text(
                            'Log New Vital Reading',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _metricTabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _metricTabs[index];
          final isSelected = _activeMetric == tab['id'];
          final color = tab['color'] as Color;

          return InkWell(
            onTap: () => setState(() => _activeMetric = tab['id'] as String),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                    : (isDark ? AppColors.darkCard : const Color(0xFFEFF3F8)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 16,
                    color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['short'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : color)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSegmentedControl(bool isDark) {
    final periods = ['Daily', 'Weekly', 'Monthly'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF0B132B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveChartCard(BuildContext context, List<VitalRecord> records, bool isDark) {
    final hasMatchingData = _hasDataForMetric(records, _activeMetric);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasMatchingData
          ? HealthLineChart(
              activeTab: _activeMetric,
              records: records,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.show_chart_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No $_selectedPeriod ${_getMetricLabel(_activeMetric)} Records',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Record your first entry to see real trends and graphical analytics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/add-vital'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Log Reading Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildComputedStatsGrid(List<VitalRecord> records, bool isDark) {
    final stats = _computeMetricStats(records, _activeMetric);

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: 'Average',
            value: stats['avg'] ?? '--',
            unit: stats['unit'] ?? '',
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: 'Highest',
            value: stats['max'] ?? '--',
            unit: stats['unit'] ?? '',
            color: AppColors.error,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: 'Lowest',
            value: stats['min'] ?? '--',
            unit: stats['unit'] ?? '',
            color: AppColors.secondary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestVitalsOverview(List<VitalRecord> records, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Saved Readings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${records.length} total entries',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid of Real Snapshot Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _buildSnapshotCard('Blood Pressure', _getLatestBp(records), 'mmHg', AppColors.bpVital, Icons.favorite_rounded, isDark),
            _buildSnapshotCard('Blood Glucose', _getLatestGlucose(records), 'mg/dL', AppColors.glucoseVital, Icons.water_drop_rounded, isDark),
            _buildSnapshotCard('Pulse Rate', _getLatestPulse(records), 'BPM', AppColors.pulseVital, Icons.monitor_heart_rounded, isDark),
            _buildSnapshotCard('Oxygen SpO₂', _getLatestSpo2(records), '%', AppColors.spo2Vital, Icons.air_rounded, isDark),
            _buildSnapshotCard('Body Temp', _getLatestTemp(records), '°C', AppColors.tempVital, Icons.thermostat_rounded, isDark),
            _buildSnapshotCard('Body Weight', _getLatestWeight(records), 'kg', AppColors.weightVital, Icons.scale_rounded, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(String title, String value, String unit, Color color, IconData icon, bool isDark) {
    final hasValue = value != '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: hasValue
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ),
                if (hasValue) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDataForMetric(List<VitalRecord> records, String metric) {
    switch (metric) {
      case 'bp':
        return records.any((r) => r.systolic != null && r.diastolic != null);
      case 'glucose':
        return records.any((r) => r.glucoseValue != null);
      case 'pulse':
        return records.any((r) => r.pulseRate != null);
      case 'spo2':
        return records.any((r) => r.oxygenSaturation != null);
      case 'temp':
        return records.any((r) => r.bodyTemperature != null);
      case 'weight':
        return records.any((r) => r.weight != null);
      default:
        return false;
    }
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'bp':
        return 'Blood Pressure';
      case 'glucose':
        return 'Blood Glucose';
      case 'pulse':
        return 'Pulse Rate';
      case 'spo2':
        return 'Oxygen Saturation';
      case 'temp':
        return 'Temperature';
      case 'weight':
        return 'Weight';
      default:
        return 'Vital';
    }
  }

  Map<String, String> _computeMetricStats(List<VitalRecord> records, String metric) {
    switch (metric) {
      case 'bp':
        final valid = records.where((r) => r.systolic != null && r.diastolic != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': 'mmHg'};
        final avgSys = valid.map((r) => r.systolic!).reduce((a, b) => a + b) / valid.length;
        final avgDia = valid.map((r) => r.diastolic!).reduce((a, b) => a + b) / valid.length;
        final maxSys = valid.map((r) => r.systolic!).reduce((a, b) => a > b ? a : b);
        final minSys = valid.map((r) => r.systolic!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': '${avgSys.round()}/${avgDia.round()}',
          'max': '${maxSys.round()}',
          'min': '${minSys.round()}',
          'unit': 'mmHg',
        };
      case 'glucose':
        final valid = records.where((r) => r.glucoseValue != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': 'mg/dL'};
        final avg = valid.map((r) => r.glucoseValue!).reduce((a, b) => a + b) / valid.length;
        final max = valid.map((r) => r.glucoseValue!).reduce((a, b) => a > b ? a : b);
        final min = valid.map((r) => r.glucoseValue!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': avg.toStringAsFixed(0),
          'max': max.toStringAsFixed(0),
          'min': min.toStringAsFixed(0),
          'unit': 'mg/dL',
        };
      case 'pulse':
        final valid = records.where((r) => r.pulseRate != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': 'BPM'};
        final avg = valid.map((r) => r.pulseRate!).reduce((a, b) => a + b) / valid.length;
        final max = valid.map((r) => r.pulseRate!).reduce((a, b) => a > b ? a : b);
        final min = valid.map((r) => r.pulseRate!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': avg.round().toString(),
          'max': max.round().toString(),
          'min': min.round().toString(),
          'unit': 'BPM',
        };
      case 'spo2':
        final valid = records.where((r) => r.oxygenSaturation != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': '%'};
        final avg = valid.map((r) => r.oxygenSaturation!).reduce((a, b) => a + b) / valid.length;
        final max = valid.map((r) => r.oxygenSaturation!).reduce((a, b) => a > b ? a : b);
        final min = valid.map((r) => r.oxygenSaturation!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': avg.toStringAsFixed(1),
          'max': max.toStringAsFixed(1),
          'min': min.toStringAsFixed(1),
          'unit': '%',
        };
      case 'temp':
        final valid = records.where((r) => r.bodyTemperature != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': '°C'};
        final avg = valid.map((r) => r.bodyTemperature!).reduce((a, b) => a + b) / valid.length;
        final max = valid.map((r) => r.bodyTemperature!).reduce((a, b) => a > b ? a : b);
        final min = valid.map((r) => r.bodyTemperature!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': avg.toStringAsFixed(1),
          'max': max.toStringAsFixed(1),
          'min': min.toStringAsFixed(1),
          'unit': '°C',
        };
      case 'weight':
        final valid = records.where((r) => r.weight != null).toList();
        if (valid.isEmpty) return {'avg': '--', 'max': '--', 'min': '--', 'unit': 'kg'};
        final avg = valid.map((r) => r.weight!).reduce((a, b) => a + b) / valid.length;
        final max = valid.map((r) => r.weight!).reduce((a, b) => a > b ? a : b);
        final min = valid.map((r) => r.weight!).reduce((a, b) => a < b ? a : b);
        return {
          'avg': avg.toStringAsFixed(1),
          'max': max.toStringAsFixed(1),
          'min': min.toStringAsFixed(1),
          'unit': 'kg',
        };
      default:
        return {'avg': '--', 'max': '--', 'min': '--', 'unit': ''};
    }
  }

  String _getLatestBp(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.systolic != null && r.diastolic != null) {
        return '${r.systolic!.toInt()}/${r.diastolic!.toInt()}';
      }
    }
    return '--';
  }

  String _getLatestGlucose(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.glucoseValue != null) {
        return r.glucoseValue!.toStringAsFixed(0);
      }
    }
    return '--';
  }

  String _getLatestPulse(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.pulseRate != null) {
        return '${r.pulseRate!.toInt()}';
      }
    }
    return '--';
  }

  String _getLatestSpo2(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.oxygenSaturation != null) {
        return r.oxygenSaturation!.toStringAsFixed(0);
      }
    }
    return '--';
  }

  String _getLatestTemp(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.bodyTemperature != null) {
        return r.bodyTemperature!.toStringAsFixed(1);
      }
    }
    return '--';
  }

  String _getLatestWeight(List<VitalRecord> records) {
    for (var r in records.reversed) {
      if (r.weight != null) {
        return r.weight!.toStringAsFixed(1);
      }
    }
    return '--';
  }
}
