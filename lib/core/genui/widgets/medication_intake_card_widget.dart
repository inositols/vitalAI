import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';

/// Dynamic interactive medication intake card allowing 1-tap confirmation and reminder scheduling.
class MedicationIntakeCardWidget extends StatefulWidget {
  final GenUiMedicationIntakeModel model;

  const MedicationIntakeCardWidget({
    super.key,
    required this.model,
  });

  @override
  State<MedicationIntakeCardWidget> createState() => _MedicationIntakeCardWidgetState();
}

class _MedicationIntakeCardWidgetState extends State<MedicationIntakeCardWidget> {
  bool _isTaken = false;
  String? _takenTimeStr;
  bool _isReminderSet = false;

  @override
  void initState() {
    super.initState();
    _isTaken = widget.model.status == 'taken';
  }

  void _markAsTaken() {
    if (_isTaken) return;
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedTime = '$displayHour:$minute ${isPm ? "PM" : "AM"}';

    setState(() {
      _isTaken = true;
      _takenTimeStr = formattedTime;
    });

    GenUiActionHandler.markMedicationTaken(
      context,
      medicationName: widget.model.medicationName,
      dosage: widget.model.dosage,
    );
  }

  void _scheduleReminder() {
    if (_isReminderSet) return;
    HapticFeedback.selectionClick();
    setState(() => _isReminderSet = true);

    GenUiActionHandler.quickSaveReminder(
      context,
      title: 'Take ${widget.model.medicationName}',
      timeStr: widget.model.scheduledTime,
      dosage: widget.model.dosage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTaken
              ? AppColors.success.withValues(alpha: isDark ? 0.4 : 0.3)
              : AppColors.tertiary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Medication Name, Scheduled Time Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isTaken
                      ? AppColors.success.withValues(alpha: 0.14)
                      : AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: _isTaken ? AppColors.success : AppColors.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.medicationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                    ),
                    if (widget.model.dosage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Dose: ${widget.model.dosage}${widget.model.frequency != null ? " • ${widget.model.frequency}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isTaken
                      ? AppColors.success.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isTaken
                        ? AppColors.success.withValues(alpha: 0.4)
                        : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTaken ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 12,
                      color: _isTaken ? AppColors.success : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isTaken
                          ? 'TAKEN'
                          : widget.model.scheduledTime.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isTaken ? AppColors.success : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Instructions Note
          if (widget.model.instructions != null && widget.model.instructions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.model.instructions!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 1. Mark as Taken Button
              InkWell(
                onTap: _isTaken ? null : _markAsTaken,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isTaken
                        ? AppColors.success.withValues(alpha: 0.18)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isTaken
                          ? AppColors.success
                          : AppColors.success.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTaken ? Icons.check_circle_rounded : Icons.check_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTaken
                            ? 'Taken${_takenTimeStr != null ? ' ($takenTimeStr)' : ''}'
                            : 'Mark as Taken',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Set Dose Reminder Button
              InkWell(
                onTap: _isReminderSet ? null : _scheduleReminder,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isReminderSet
                        ? AppColors.tertiary.withValues(alpha: 0.18)
                        : AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isReminderSet
                          ? AppColors.tertiary
                          : AppColors.tertiary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isReminderSet
                            ? Icons.notifications_active_rounded
                            : Icons.alarm_add_rounded,
                        size: 14,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isReminderSet ? 'Reminder Set ✓' : 'Add to Reminders',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? get takenTimeStr => _takenTimeStr;
}
