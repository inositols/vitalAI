import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import '../../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../../features/patients/presentation/bloc/patient_state.dart';
import '../../../features/reminders/data/models/reminder_model.dart';
import '../../../features/reminders/presentation/bloc/reminders_bloc.dart';
import '../../../features/reminders/presentation/bloc/reminders_event.dart';
import '../../../features/reminders/presentation/widgets/add_reminder_sheet.dart';
import '../../../features/vitals/data/models/vital_record.dart';
import '../../../features/vitals/presentation/bloc/vitals_bloc.dart';
import '../../../features/vitals/presentation/bloc/vitals_event.dart';
import '../../theme/design_tokens.dart';

/// Interactive Action Handler for GenUI components enabling direct inline user actions.
class GenUiActionHandler {
  /// Quick 1-Tap Save Vital reading directly into the database.
  static Future<void> quickSaveVital(
    BuildContext context, {
    required String metricType,
    required String rawValue,
    String? unit,
  }) async {
    try {
      final patientState = context.read<PatientBloc>().state;
      final patientId = patientState is PatientLoadSuccess && patientState.activePatient != null
          ? patientState.activePatient!.id
          : 1;

      final record = VitalRecord()
        ..remoteId = const Uuid().v4()
        ..patientId = patientId
        ..dateTime = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isSynced = false
        ..tags = ['genui_ai_logged'];

      final lowerType = metricType.toLowerCase();

      if (lowerType.contains('pressure') || lowerType.contains('bp')) {
        final parts = rawValue.replaceAll(RegExp(r'[^0-9/]'), '').split('/');
        if (parts.length == 2) {
          record.systolic = double.tryParse(parts[0]);
          record.diastolic = double.tryParse(parts[1]);
        }
      } else if (lowerType.contains('glucose') || lowerType.contains('sugar')) {
        final numStr = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
        record.glucoseValue = double.tryParse(numStr);
        record.glucoseMealContext = 'random';
      } else if (lowerType.contains('pulse') || lowerType.contains('heart')) {
        final numStr = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
        record.pulseRate = double.tryParse(numStr);
      } else if (lowerType.contains('spo2') || lowerType.contains('oxygen')) {
        final numStr = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
        record.oxygenSaturation = double.tryParse(numStr);
      } else if (lowerType.contains('temp')) {
        final numStr = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
        record.bodyTemperature = double.tryParse(numStr);
      } else if (lowerType.contains('weight')) {
        final numStr = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
        record.weight = double.tryParse(numStr);
      }

      context.read<VitalsBloc>().add(VitalsRecordSaved(record));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recorded $rawValue ${unit ?? ''} to vitals history',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View Charts',
              textColor: AppColors.primaryLight,
              onPressed: () => context.push('/vitals'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reading: $e')),
        );
      }
    }
  }

  /// Quick 1-Tap Save Medication Reminder into the database.
  static Future<void> quickSaveReminder(
    BuildContext context, {
    required String title,
    String? timeStr,
    String? dosage,
  }) async {
    try {
      final patientState = context.read<PatientBloc>().state;
      final patientId = patientState is PatientLoadSuccess && patientState.activePatient != null
          ? patientState.activePatient!.id
          : 1;

      int hour = 8;
      int minute = 0;

      if (timeStr != null && timeStr.contains(':')) {
        final clean = timeStr.trim().toUpperCase();
        final isPm = clean.contains('PM');
        final isAm = clean.contains('AM');
        final timePart = clean.replaceAll(RegExp(r'[^0-9:]'), '');
        final parts = timePart.split(':');
        if (parts.length >= 2) {
          hour = int.tryParse(parts[0]) ?? 8;
          minute = int.tryParse(parts[1]) ?? 0;
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }

      final formattedTime =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';

      final fullTitle = dosage != null && dosage.isNotEmpty ? '$title ($dosage)' : title;

      final reminder = ReminderModel(
        id: const Uuid().v4(),
        patientId: patientId,
        title: fullTitle,
        time: formattedTime,
        hour: hour,
        minute: minute,
        iconCodePoint: 0xe0b2,
        createdAt: DateTime.now(),
      );

      context.read<RemindersBloc>().add(ReminderAdded(reminder));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reminder set for "$fullTitle" at $formattedTime',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View Reminders',
              textColor: AppColors.secondary,
              onPressed: () => context.push('/reminders'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set reminder: $e')),
        );
      }
    }
  }

  /// Sends a follow-up query directly into the AI Assistant chat.
  static void askFollowUp(BuildContext context, String query) {
    context.read<AiAssistantBloc>().add(AiAssistantSendMessage(query));
  }

  /// Navigates to Vitals Entry page to record a new vital reading.
  static void logVital(BuildContext context, {String? metricType}) {
    context.push('/add-vital');
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
