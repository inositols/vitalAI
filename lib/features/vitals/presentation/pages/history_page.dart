import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';
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
    if (patientState is PatientLoadSuccess &&
        patientState.activePatient != null) {
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
    final settingsState = context.watch<SettingsBloc>().state;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess ||
            patientState.activePatient == null) {
          return const Scaffold(
            body: Center(child: Text("Please select a patient profile first.")),
          );
        }

        final patient = patientState.activePatient!;

        return BlocBuilder<VitalsBloc, VitalsState>(
          builder: (context, vitalsState) {
            final records = vitalsState is VitalsLoadSuccess
                ? vitalsState.records
                : <VitalRecord>[];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Log History'),
                actions: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.share),
                    tooltip: 'Export PDF Report',
                    onPressed: records.isEmpty
                        ? null
                        : () => _exportPdf(context, records, patient.name),
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
                    child: _buildListContent(
                        context, vitalsState, patient.id, settingsState),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListContent(
    BuildContext context,
    VitalsState vitalsState,
    int patientId,
    SettingsState settings,
  ) {
    final theme = Theme.of(context);
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
                  CupertinoIcons.search,
                  size: 72,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Records Match Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: records.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemBuilder: (context, index) {
          final r = records[index];
          return _buildHistoryListItem(context, r, patientId, settings);
        },
      );
    }

    return const SizedBox();
  }

  Future<void> _exportPdf(
      BuildContext context, List<VitalRecord> records, String patientName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VitalAI Health Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        DateTime.now().toString().split(' ')[0],
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Patient Name: $patientName',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Date/Time',
                    'BP (Sys/Dia)',
                    'Glucose',
                    'Pulse',
                    'SpO2',
                    'Temp'
                  ],
                  data: records.map((r) {
                    final bpStr = (r.systolic != null && r.diastolic != null)
                        ? '${r.systolic!.toInt()}/${r.diastolic!.toInt()}'
                        : 'N/A';
                    final glucoseStr = r.glucoseValue != null
                        ? '${r.glucoseValue!.toStringAsFixed(1)}'
                        : 'N/A';
                    final pulseStr =
                        r.pulseRate != null ? '${r.pulseRate!.toInt()}' : 'N/A';
                    final spo2Str = r.oxygenSaturation != null
                        ? '${r.oxygenSaturation!.toInt()}%'
                        : 'N/A';
                    final tempStr = r.bodyTemperature != null
                        ? '${r.bodyTemperature!.toStringAsFixed(1)}°C'
                        : 'N/A';

                    return [
                      r.dateTime.toString().substring(0, 16),
                      bpStr,
                      glucoseStr,
                      pulseStr,
                      spo2Str,
                      tempStr,
                    ];
                  }).toList(),
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey100),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Generated securely by VitalAI. This report is for educational track purposes only.',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Show PDF print / export share preview UI
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'VitalAI_Report_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }

  Widget _buildFilterChipsList(ThemeData theme) {
    final filterOptions = [
      {'value': null, 'label': 'All', 'icon': CupertinoIcons.square_grid_2x2},
      {
        'value': 'blood_pressure',
        'label': 'Blood Pressure',
        'icon': CupertinoIcons.heart
      },
      {
        'value': 'glucose',
        'label': 'Blood Glucose',
        'icon': CupertinoIcons.drop
      },
      {
        'value': 'pulse',
        'label': 'Heart Rate',
        'icon': CupertinoIcons.waveform_path_ecg
      },
      {'value': 'oxygen', 'label': 'Oxygen SpO₂', 'icon': CupertinoIcons.wind},
      {
        'value': 'temperature',
        'label': 'Temperature',
        'icon': CupertinoIcons.thermometer
      },
      {
        'value': 'weight',
        'label': 'Weight',
        'icon': CupertinoIcons.arrow_down_to_line_alt
      },
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final opt = filterOptions[index];
          final isSelected = _vitalType == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                opt['icon'] as IconData,
                size: 14,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
              ),
              label: Text(opt['label'] as String),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Georgia',
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : theme.dividerColor.withOpacity(0.08),
                  width: 1,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _vitalType = opt['value'] as String?);
                  _refresh();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Metric Type Chips
          _buildFilterChipsList(theme),
          const SizedBox(height: 12),

          // 2. Date Selection & Abnormal Toggle Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate == null
                                  ? 'Filter by Date...'
                                  : '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_startDate != null)
                            GestureDetector(
                              onTap: () {
                                _clearDateRange();
                              },
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Abnormal Switch Chip
                FilterChip(
                  avatar: Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 13,
                    color: _abnormalOnly ? Colors.white : Colors.orange,
                  ),
                  label: const Text('Abnormal Only'),
                  selected: _abnormalOnly,
                  selectedColor: Colors.orange.shade800,
                  backgroundColor: theme.colorScheme.surface,
                  labelStyle: TextStyle(
                    color: _abnormalOnly
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        _abnormalOnly ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Georgia',
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _abnormalOnly
                          ? Colors.transparent
                          : theme.dividerColor.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _abnormalOnly = val);
                    _refresh();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListItem(
    BuildContext context,
    VitalRecord r,
    int patientId,
    SettingsState settings,
  ) {
    final theme = Theme.of(context);
    final text = _buildReadingDescription(r, settings);
    final title = _getReadingTitle(r);
    final iconData = _getReadingIcon(r);
    final isAbnormal = _checkAbnormalStatus(r);

    // Choose icon color & background color based on status
    final statusColor =
        isAbnormal ? const Color(0xFFFF5B4E) : const Color(0xFF008A5E);
    final statusBg = statusColor.withOpacity(0.08);

    return Dismissible(
      key: Key(r.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Delete Reading?'),
            content: const Text(
                'Are you sure you want to delete this vital record permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text('Delete',
                    style: TextStyle(color: theme.colorScheme.error)),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAbnormal
                ? const Color(0xFFFF5B4E).withOpacity(0.25)
                : theme.dividerColor.withOpacity(0.06),
            width: isAbnormal ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon, Category Name, and DateTime
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime12h(r.dateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Row: Reading & Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isAbnormal ? const Color(0xFFFF5B4E) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAbnormal ? 'Abnormal' : 'Normal',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Note Row (if present)
              if (r.note != null && r.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_plaintext,
                        size: 14,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.note!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
    if (r.pulseRate != null && r.oxygenSaturation != null)
      return 'Pulse & SpO₂';
    if (r.pulseRate != null) return 'Heart Rate';
    if (r.bodyTemperature != null) return 'Body Temperature';
    if (r.weight != null) return 'Body Weight';
    return 'Vitals Record';
  }

  IconData _getReadingIcon(VitalRecord r) {
    if (r.systolic != null) return CupertinoIcons.heart;
    if (r.glucoseValue != null) return CupertinoIcons.drop;
    if (r.pulseRate != null) return CupertinoIcons.waveform_path_ecg;
    if (r.bodyTemperature != null) return CupertinoIcons.thermometer;
    if (r.weight != null) return CupertinoIcons.arrow_down_to_line_alt;
    return CupertinoIcons.square_list;
  }

  String _buildReadingDescription(VitalRecord r, SettingsState settings) {
    final buffer = StringBuffer();
    if (r.systolic != null && r.diastolic != null) {
      buffer.write('${r.systolic?.toInt()}/${r.diastolic?.toInt()} mmHg');
    }
    if (r.glucoseValue != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      double val = r.glucoseValue!;
      if (settings.glucoseUnit == 'mmol/L') {
        val = val / 18.018;
      }
      final valStr = settings.glucoseUnit == 'mmol/L'
          ? val.toStringAsFixed(1)
          : val.toInt().toString();
      buffer.write('$valStr ${settings.glucoseUnit}');
      if (r.glucoseMealContext != null) {
        buffer.write(' (${r.glucoseMealContext})');
      }
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
      double val = r.bodyTemperature!;
      if (settings.tempUnit == 'F') {
        val = (val * 9 / 5) + 32;
      }
      buffer.write('${val.toStringAsFixed(1)}°${settings.tempUnit}');
    }
    if (r.weight != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      double val = r.weight!;
      if (settings.weightUnit == 'lbs') {
        val = val * 2.20462;
      }
      buffer.write('${val.toStringAsFixed(1)} ${settings.weightUnit}');
      if (r.bmi != null) {
        buffer.write(' (BMI: ${r.bmi!.toStringAsFixed(1)})');
      }
    }
    return buffer.toString();
  }

  bool _checkAbnormalStatus(VitalRecord r) {
    if (r.systolic != null && (r.systolic! >= 130 || r.systolic! < 90))
      return true;
    if (r.diastolic != null && (r.diastolic! >= 85 || r.diastolic! < 60))
      return true;
    if (r.oxygenSaturation != null && r.oxygenSaturation! < 95) return true;
    if (r.glucoseValue != null &&
        (r.glucoseValue! >= 140 || r.glucoseValue! < 70)) return true;
    return false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime12h(DateTime dt) {
    final dateStr = '${dt.month}/${dt.day}/${dt.year}';
    final hour24 = dt.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$dateStr $hour12:$minuteStr $period';
  }
}
