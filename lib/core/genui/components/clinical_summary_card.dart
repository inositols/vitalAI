import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';

/// Clinical summary card containing structured facts strictly from verified patient records.
class ClinicalSummaryCard extends StatelessWidget {
  final GenUiComponent component;
  final GenUiActionCallback? onActionSelected;

  const ClinicalSummaryCard({
    super.key,
    required this.component,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final d = component.data;
    final patientName = d['patientName']?.toString() ?? 'Patient';
    final age = d['age']?.toString();
    final vitals = d['latestVitals'] as Map? ?? d['vitals'] as Map? ?? {};
    final medicalHistory = (d['medicalHistory'] as List?) ?? [];
    final medications = (d['medications'] as List?) ?? [];
    final clinicalNotes = (d['clinicalNotes'] as List?) ?? [];
    final missingInfo = (d['missingInfo'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Badge distinguishing recorded facts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Clinical Summary: $patientName',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Verified Record',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (age != null) ...[
            const SizedBox(height: 2),
            Text('Age: $age years', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
          ],
          const Divider(height: 16, color: AppColors.lightBorder),

          // Section 1: Latest Vital Signs
          _buildSectionHeader('Latest Vital Signs', Icons.monitor_heart_outlined),
          if (vitals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: vitals.entries.map((e) {
                  return Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                  );
                }).toList(),
              ),
            )
          else
            _buildEmptySectionText('No vital readings recorded yet.'),

          // Section 2: Medical History
          _buildSectionHeader('Recorded Medical History', Icons.history_edu_rounded),
          if (medicalHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: medicalHistory.map((item) => Text('• $item', style: const TextStyle(fontSize: 12.5, color: AppColors.navy))).toList(),
              ),
            )
          else
            _buildEmptySectionText('No prior conditions recorded.'),

          // Section 3: Medication History
          _buildSectionHeader('Medication History', Icons.medication_outlined),
          if (medications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: medications.map((item) => Text('• $item', style: const TextStyle(fontSize: 12.5, color: AppColors.navy))).toList(),
              ),
            )
          else
            _buildEmptySectionText('No active medications on file.'),

          // Section 4: Clinical Notes
          if (clinicalNotes.isNotEmpty) ...[
            _buildSectionHeader('Recent Clinical Notes', Icons.description_outlined),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: clinicalNotes.map((item) => Text('• $item', style: const TextStyle(fontSize: 12.5, color: AppColors.navy))).toList(),
              ),
            ),
          ],

          // Section 5: Missing Information
          if (missingInfo.isNotEmpty) ...[
            _buildSectionHeader('Missing Information', Icons.help_outline_rounded, isMuted: true),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingInfo.map((item) => Text('• $item (Pending)', style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted))).toList(),
              ),
            ),
          ],

          const Divider(height: 16, color: AppColors.lightBorder),

          // Next Actions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildSummaryAction(
                label: 'View full history',
                icon: Icons.history_rounded,
                actionType: GenUiActionType.viewVitalHistory,
              ),
              _buildSummaryAction(
                label: 'View vital trends',
                icon: Icons.trending_up_rounded,
                actionType: GenUiActionType.viewTrends,
              ),
              _buildSummaryAction(
                label: 'Edit patient details',
                icon: Icons.edit_note_rounded,
                actionType: GenUiActionType.editPatient,
              ),
              _buildSummaryAction(
                label: 'Ask another question',
                icon: Icons.chat_bubble_outline_rounded,
                actionType: GenUiActionType.askQuestion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isMuted ? AppColors.lightTextMuted : AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMuted ? AppColors.lightTextMuted : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.lightTextMuted),
      ),
    );
  }

  Widget _buildSummaryAction({
    required String label,
    required IconData icon,
    required GenUiActionType actionType,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 13, color: AppColors.primary),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.navy),
      backgroundColor: AppColors.lightContainer,
      side: const BorderSide(color: AppColors.lightBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onPressed: () {
        onActionSelected?.call(GenUiAction(
          id: label.toLowerCase().replaceAll(' ', '_'),
          type: actionType,
          label: label,
        ));
      },
    );
  }
}

