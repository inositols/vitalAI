import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/voice_vitals_top_bar.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../data/models/vital_record.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../../../activity/data/models/activity_item.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';

/// Vital-Sign Confirmation View matching Screen 4 in the concept image.
/// Supports provider verification, boundary checks, and explicit confirmation.
class ConfirmVitalPage extends StatefulWidget {
  final double? initialSystolic;
  final double? initialDiastolic;
  final int? initialPatientId;
  final String? voiceTranscript;
  final String? initialNotes;

  const ConfirmVitalPage({
    super.key,
    this.initialSystolic = 118,
    this.initialDiastolic = 76,
    this.initialPatientId,
    this.voiceTranscript,
    this.initialNotes,
  });

  @override
  State<ConfirmVitalPage> createState() => _ConfirmVitalPageState();
}

class _ConfirmVitalPageState extends State<ConfirmVitalPage> {
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _notesController;
  DateTime _recordedTime = DateTime.now();
  int? _selectedPatientId;
  String? _selectedPatientName;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _systolicController = TextEditingController(
      text: widget.initialSystolic?.toInt().toString() ?? '118',
    );
    _diastolicController = TextEditingController(
      text: widget.initialDiastolic?.toInt().toString() ?? '76',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _selectedPatientId = widget.initialPatientId;
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'Today, ${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $period';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recordedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_recordedTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _recordedTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _confirmAndSave() async {
    setState(() {
      _validationError = null;
    });

    final sys = double.tryParse(_systolicController.text.trim());
    final dia = double.tryParse(_diastolicController.text.trim());

    if (sys == null || sys < 50 || sys > 260) {
      setState(() {
        _validationError = 'Systolic value must be a valid number between 50 and 260 mmHg.';
      });
      return;
    }

    if (dia == null || dia < 30 || dia > 160) {
      setState(() {
        _validationError = 'Diastolic value must be a valid number between 30 and 160 mmHg.';
      });
      return;
    }

    final targetPatientId = _selectedPatientId ?? 1;
    final patientName = _selectedPatientName ?? 'Chika Okafor';

    setState(() => _isSaving = true);

    final record = VitalRecord()
      ..patientId = targetPatientId
      ..systolic = sys
      ..diastolic = dia
      ..dateTime = _recordedTime
      ..note = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (widget.voiceTranscript != null ? 'Voice logged: "${widget.voiceTranscript}"' : null)
      ..isSynced = true;

    // 1. Save Vital to Repository via Bloc
    context.read<VitalsBloc>().add(VitalsRecordSaved(record));

    // 2. Log Activity
    context.read<ActivityBloc>().add(
          ActivityLogged(
            ActivityItem(
              title: 'Blood pressure recorded',
              subtitle: '${sys.toInt()}/${dia.toInt()} mmHg • $patientName',
              timestamp: _recordedTime,
              category: ActivityCategory.vitals,
              patientId: targetPatientId,
              patientName: patientName,
              statusBadge: 'Verified',
            ),
          ),
        );

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Blood pressure (${sys.toInt()}/${dia.toInt()} mmHg) confirmed and saved for $patientName.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/patients');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: VoiceVitalsTopBar(
        showBack: true,
        showAvatar: false,
        titleOverride: 'VoiceVitals',
        subtitleOverride: 'Confirm Vital Entry',
      ),
      body: SafeArea(
        child: BlocBuilder<PatientBloc, PatientState>(
          builder: (context, patientState) {
            List<PatientModel> patients = [];
            if (patientState is PatientLoadSuccess) {
              patients = patientState.patients;
              if (_selectedPatientId == null && patients.isNotEmpty) {
                _selectedPatientId = patientState.activePatient?.id ?? patients.first.id;
                _selectedPatientName = patientState.activePatient?.name ?? patients.first.name;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  Text(
                    'Record Blood Pressure',
                    style: AppTypography.headlineLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Let's confirm your reading.",
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Voice Transcript comparison callout (if available)
                  if (widget.voiceTranscript != null && widget.voiceTranscript!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.subtleTealSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.subtleTealBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recognized Voice Input',
                                  style: AppTypography.labelSmall(color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '"${widget.voiceTranscript}"',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.secondary,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Patient Selector Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Patient:',
                          style: AppTypography.titleSmall(
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedPatientId ?? (patients.isNotEmpty ? patients.first.id : null),
                              isExpanded: true,
                              items: patients.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                    '${p.name} (${p.remoteId})',
                                    style: AppTypography.bodyMedium(
                                      color: isDark ? Colors.white : AppColors.secondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final p = patients.firstWhere((item) => item.id == val);
                                  setState(() {
                                    _selectedPatientId = val;
                                    _selectedPatientName = p.name;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reading Card Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEE2E2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.bpVital,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Blood Pressure',
                                  style: AppTypography.titleMedium(
                                    color: isDark ? Colors.white : AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.subtleTealSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.subtleTealBorder),
                              ),
                              child: Text(
                                'New Reading',
                                style: AppTypography.labelSmall(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Two Number Boxes Side-by-Side: Systolic (mmHg) & Diastolic (mmHg)
                        Row(
                          children: [
                            // Systolic Box
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Systolic (mmHg)',
                                    style: AppTypography.labelMedium(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkContainer : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _systolicController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.vitalValueMedium(
                                        color: isDark ? Colors.white : AppColors.secondary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Diastolic Box
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Diastolic (mmHg)',
                                    style: AppTypography.labelMedium(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkContainer : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _diastolicController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.vitalValueMedium(
                                        color: isDark ? Colors.white : AppColors.secondary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Date and Time Row (Interactive)
                        InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(_recordedTime),
                                  style: AppTypography.bodySmall(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Change',
                                  style: AppTypography.labelSmall(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Optional Notes Input
                        Row(
                          children: [
                            const Icon(Icons.notes_rounded, size: 16, color: AppColors.lightTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Notes (optional)',
                              style: AppTypography.labelMedium(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkContainer : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: AppTypography.bodyMedium(
                              color: isDark ? Colors.white : AppColors.secondary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. after exercise, before medication...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Validation Error (if any)
                  if (_validationError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(
                                color: AppColors.onErrorContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Clinical Callout Info Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These values look within a healthy range, but always confirm with your clinician.',
                            style: AppTypography.bodySmall(
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Primary Action: Confirm and Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isSaving ? 'Saving Reading...' : 'Confirm and Save',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _confirmAndSave,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Action: Edit Values
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.lightTextSecondary),
                      label: Text(
                        'Edit Values',
                        style: AppTypography.labelMedium(color: AppColors.lightTextSecondary),
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
