import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/reminder_model.dart';
import '../bloc/reminders_bloc.dart';
import '../bloc/reminders_event.dart';

class AddReminderSheet extends StatefulWidget {
  final int patientId;

  const AddReminderSheet({super.key, required this.patientId});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _titleController = TextEditingController(text: 'Blood Pressure Log');
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedIconCodePoint = Icons.favorite_rounded.codePoint;

  static const _availableIcons = [
    Icons.favorite_rounded,
    Icons.water_drop_rounded,
    Icons.alarm_rounded,
    Icons.thermostat_rounded,
    Icons.monitor_heart_rounded,
    Icons.medication_rounded,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final hourStr = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedTime = '${hourStr.toString().padLeft(2, '0')}:$minuteStr $period';

    final pId = widget.patientId > 0 ? widget.patientId : 1;

    final reminder = ReminderModel(
      id: const Uuid().v4(),
      patientId: pId,
      title: title,
      time: formattedTime,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      iconCodePoint: _selectedIconCodePoint,
      isCompleted: false,
      isEnabled: true,
      createdAt: DateTime.now(),
    );

    context.read<RemindersBloc>().add(ReminderAdded(reminder));
    context.showSnackBar('✓ Reminder scheduled for $formattedTime');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Health Reminder',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Reminder Title',
              hintText: 'e.g., Morning Blood Pressure',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reminder Time: ${_selectedTime.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: const Text('Change Time'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Icon Category',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _availableIcons.map((icon) {
              final isSelected = icon.codePoint == _selectedIconCodePoint;
              return InkWell(
                onTap: () => setState(() => _selectedIconCodePoint = icon.codePoint),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Text('Save & Schedule Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
