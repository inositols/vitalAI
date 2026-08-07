import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../../features/patients/presentation/bloc/patient_state.dart';
import '../../../features/reminders/presentation/widgets/add_reminder_sheet.dart';
import '../../theme/design_tokens.dart';

/// Interactive Action Handler for GenUI components enabling direct inline user actions.
class GenUiActionHandler {
  /// Navigates to Vitals Entry page to record a new vital reading.
  static void logVital(BuildContext context, {String? metricType}) {
    context.push('/add-vital');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Vitals logger${metricType != null ? ' for $metricType' : ''}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens the Add Reminder modal bottom sheet with pre-populated values.
  static void setReminder(BuildContext context, {String? title}) {
    final patientState = context.read<PatientBloc>().state;
    final patientId = patientState is PatientLoadSuccess && patientState.activePatient != null
        ? patientState.activePatient!.id
        : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddReminderSheet(patientId: patientId),
    );
  }

  /// Generates and previews a clinical PDF report directly from a GenUI report payload.
  static Future<void> generatePdfReport(
    BuildContext context, {
    required String patientName,
    required String summaryText,
    Map<String, String>? vitalsOverview,
    List<String>? aiObservations,
  }) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VitalAI Clinical Summary Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Patient: $patientName'),
                pw.Text('Generated: ${DateTime.now().toLocal()}'),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Summary:',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(summaryText),
                if (vitalsOverview != null && vitalsOverview.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text(
                    'Vitals Breakdown:',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  pw.TableHelper.fromTextArray(
                    headers: ['Metric', 'Recorded Value'],
                    data: vitalsOverview.entries.map((e) => [e.key.toUpperCase(), e.value]).toList(),
                  ),
                ],
                if (aiObservations != null && aiObservations.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text(
                    'AI Clinical Observations:',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  ...aiObservations.map((obs) => pw.Bullet(text: obs)),
                ],
                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.Text(
                  'Note: This document was generated automatically by VitalAI and does not replace medical advice from a licensed physician.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'VitalAI_Report_${patientName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }
}
