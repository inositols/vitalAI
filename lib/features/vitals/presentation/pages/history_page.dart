import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';
import '../../data/models/vital_record.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/vital_record_card.dart';

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

  Future<void> _exportPdf(List<VitalRecord> records, String patientName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VitalAI Health Log Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Patient: $patientName'),
              pw.Text('Generated: ${DateTime.now()}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Date/Time', 'Systolic', 'Diastolic', 'Glucose', 'Pulse'],
                data: records.map((r) {
                  return [
                    '${r.dateTime.month}/${r.dateTime.day} ${r.dateTime.hour}:${r.dateTime.minute}',
                    r.systolic?.toInt().toString() ?? '-',
                    r.diastolic?.toInt().toString() ?? '-',
                    r.glucoseValue?.toInt().toString() ?? '-',
                    r.pulseRate?.toInt().toString() ?? '-',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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

        return BlocBuilder<VitalsBloc, VitalsState>(
          builder: (context, vitalsState) {
            final records =
                vitalsState is VitalsLoadSuccess ? vitalsState.records : <VitalRecord>[];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Log History'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Export PDF Report',
                    onPressed: records.isEmpty
                        ? null
                        : () => _exportPdf(records, patient.name),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: HistoryFilterBar(
                        selectedVitalType: _vitalType,
                        startDate: _startDate,
                        endDate: _endDate,
                        abnormalOnly: _abnormalOnly,
                        onTypeChanged: (val) {
                          setState(() => _vitalType = val);
                          _refresh();
                        },
                        onSelectDateRange: _selectDateRange,
                        onClearDateRange: _clearDateRange,
                        onAbnormalChanged: (val) {
                          setState(() => _abnormalOnly = val);
                          _refresh();
                        },
                      ),
                    ),
                    Expanded(
                      child: vitalsState is VitalsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : records.isEmpty
                              ? Center(
                                  child: Text(
                                    'No records found.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: records.length,
                                  itemBuilder: (ctx, index) {
                                    final r = records[index];
                                    return VitalRecordCard(
                                      record: r,
                                      onDelete: () {
                                        context.read<VitalsBloc>().add(
                                              VitalsRecordDeleted(
                                                localId: r.id,
                                                remoteId: r.remoteId,
                                                patientId: patient.id,
                                              ),
                                            );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
