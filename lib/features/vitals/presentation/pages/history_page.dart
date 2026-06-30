import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';
import '../../data/models/vital_record.dart';

/// Screen displaying raw logged readings list with multiple filtering dimensions and PDF export.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _vitalType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _abnormalOnly = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      context.read<VitalsBloc>().add(
            VitalsFilteredRequested(
              patientId: patientState.activePatient!.id,
              vitalType: _vitalType,
              startDate: _startDate,
              endDate: _endDate,
              abnormalOnly: _abnormalOnly,
            ),
          );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refresh();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refresh();
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

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Log History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF Report',
                onPressed: () {
                  // In a real flow, trigger printing/export service
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating PDF Report...')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Interactive Filters Strip
              _buildFiltersBar(theme),

              // 2. Main History Log List
              Expanded(
                child: BlocBuilder<VitalsBloc, VitalsState>(
                  builder: (context, vitalsState) {
                    if (vitalsState is VitalsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (vitalsState is VitalsFailure) {
                      return Center(
                        child: Text(
                          'Error: ${vitalsState.message}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }

                    if (vitalsState is VitalsLoadSuccess) {
                      final records = vitalsState.records;

                      if (records.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 72,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Records Match Filters',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: records.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final r = records[index];
                          return _buildHistoryListItem(context, r, patient.id);
                        },
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersBar(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _vitalType,
                    decoration: const InputDecoration(
                      labelText: 'Filter Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Metrics')),
                      DropdownMenuItem(value: 'blood_pressure', child: Text('Blood Pressure')),
                      DropdownMenuItem(value: 'glucose', child: Text('Blood Glucose')),
                      DropdownMenuItem(value: 'pulse', child: Text('Heart Rate')),
                      DropdownMenuItem(value: 'oxygen', child: Text('Oxygen SpO2')),
                      DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
                      DropdownMenuItem(value: 'weight', child: Text('Weight')),
                    ],
                    onChanged: (val) {
                      setState(() => _vitalType = val);
                      _refresh();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_startDate == null ? 'Dates' : 'Filtered'),
                  onPressed: _selectDateRange,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(88, 48),
                  ),
                ),
                if (_startDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDateRange,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Show Abnormal Only',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _abnormalOnly,
                  onChanged: (val) {
                    setState(() => _abnormalOnly = val);
                    _refresh();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryListItem(BuildContext context, VitalRecord r, int patientId) {
    final theme = Theme.of(context);
    final text = _buildReadingDescription(r);
    final title = _getReadingTitle(r);
    final iconData = _getReadingIcon(r);
    final isElevated = _checkAbnormalStatus(r);

    return Dismissible(
      key: Key(r.id.toString()),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Delete Reading?'),
            content: const Text('Are you sure you want to delete this vital record permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<VitalsBloc>().add(
              VitalsRecordDeleted(
                localId: r.id,
                remoteId: r.remoteId,
                patientId: patientId,
              ),
            );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isElevated
              ? BorderSide(color: theme.colorScheme.error.withOpacity(0.8), width: 1.5)
              : BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isElevated
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            child: Icon(
              iconData,
              color: isElevated
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${r.dateTime.hour.toString().padLeft(2, '0')}:${r.dateTime.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isElevated ? theme.colorScheme.error : null,
                ),
              ),
              if (r.note != null && r.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Note: ${r.note}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getReadingTitle(VitalRecord r) {
    if (r.systolic != null) return 'Blood Pressure';
    if (r.glucoseValue != null) return 'Blood Glucose';
    if (r.pulseRate != null && r.oxygenSaturation != null) return 'Pulse & SpO₂';
    if (r.pulseRate != null) return 'Heart Rate';
    if (r.bodyTemperature != null) return 'Body Temperature';
    if (r.weight != null) return 'Body Weight';
    return 'Vitals Record';
  }

  IconData _getReadingIcon(VitalRecord r) {
    if (r.systolic != null) return Icons.favorite_outline;
    if (r.glucoseValue != null) return Icons.opacity;
    if (r.pulseRate != null) return Icons.heart_broken;
    if (r.bodyTemperature != null) return Icons.thermostat;
    if (r.weight != null) return Icons.scale;
    return Icons.health_and_safety_outlined;
  }

  String _buildReadingDescription(VitalRecord r) {
    final buffer = StringBuffer();
    if (r.systolic != null && r.diastolic != null) {
      buffer.write('${r.systolic?.toInt()}/${r.diastolic?.toInt()} mmHg');
    }
    if (r.glucoseValue != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${r.glucoseValue?.toInt()} mg/dL (${r.glucoseMealContext})');
    }
    if (r.oxygenSaturation != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('SpO₂: ${r.oxygenSaturation?.toInt()}%');
    }
    if (r.pulseRate != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${r.pulseRate?.toInt()} BPM');
    }
    if (r.bodyTemperature != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${r.bodyTemperature}°C');
    }
    if (r.weight != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${r.weight} kg');
    }
    return buffer.toString();
  }

  bool _checkAbnormalStatus(VitalRecord r) {
    if (r.systolic != null && (r.systolic! >= 130 || r.systolic! < 90)) return true;
    if (r.diastolic != null && (r.diastolic! >= 85 || r.diastolic! < 60)) return true;
    if (r.oxygenSaturation != null && r.oxygenSaturation! < 95) return true;
    if (r.glucoseValue != null && (r.glucoseValue! >= 140 || r.glucoseValue! < 70)) return true;
    return false;
  }
}
