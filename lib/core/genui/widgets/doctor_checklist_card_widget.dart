import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';

/// GenUI component rendering an interactive checkable consultation discussion guide for physician visits.
class DoctorChecklistCardWidget extends StatefulWidget {
  final GenUiDoctorChecklistModel model;

  const DoctorChecklistCardWidget({
    super.key,
    required this.model,
  });

  @override
  State<DoctorChecklistCardWidget> createState() => _DoctorChecklistCardWidgetState();
}

class _DoctorChecklistCardWidgetState extends State<DoctorChecklistCardWidget> {
  late List<bool> _checkedStates;

  @override
  void initState() {
    super.initState();
    _checkedStates = widget.model.checklistItems.map((item) => item.isChecked).toList();
  }

  void _toggleItem(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _checkedStates[index] = !_checkedStates[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.model.checklistItems;
    final completedCount = _checkedStates.where((c) => c).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Checklist Icon, Title, Counter
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.model.appointmentFocus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$completedCount/${items.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interactive Checklist Items
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isChecked = _checkedStates[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleItem(index),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? (isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
                          : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChecked
                            ? AppColors.success.withValues(alpha: 0.4)
                            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 8),
                          child: Icon(
                            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: isChecked ? AppColors.success : const Color(0xFF94A3B8),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.question,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked
                                      ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                      : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                                  fontWeight: isChecked ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                              if (item.category != null && item.category!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.category!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Actions
          Wrap(
            spacing: 8,
            children: [
              InkWell(
                onTap: () => GenUiActionHandler.exportDoctorChecklistPdf(
                  context,
                  title: widget.model.title,
                  appointmentFocus: widget.model.appointmentFocus,
                  questions: items.map((i) => i.question).toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Print / Export Checklist PDF',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
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
}
