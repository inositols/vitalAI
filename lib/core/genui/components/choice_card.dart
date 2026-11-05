import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_component.dart';
import '../models/genui_option.dart';

/// Interactive GenUI card supporting both Single-Choice and Multiple-Choice selections.
class ChoiceCard extends StatefulWidget {
  final GenUiComponent component;
  final bool isMultiple;
  final GenUiOptionCallback? onOptionSelected;
  final GenUiMultiOptionCallback? onMultiOptionSubmitted;

  const ChoiceCard({
    super.key,
    required this.component,
    this.isMultiple = false,
    this.onOptionSelected,
    this.onMultiOptionSubmitted,
  });

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> {
  late final Set<String> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = widget.component.options
        .where((o) => o.isSelected)
        .map((o) => o.id)
        .toSet();
  }

  bool get _isMultiSelect =>
      widget.isMultiple ||
      widget.component.type == GenUiComponentTypes.multipleChoice ||
      widget.component.data['isMultiple'] == true;

  void _handleOptionTap(GenUiOption option) {
    if (_isMultiSelect) {
      setState(() {
        if (_selectedOptionIds.contains(option.id)) {
          _selectedOptionIds.remove(option.id);
        } else {
          if (option.isExclusive) {
            _selectedOptionIds.clear();
          } else {
            // Remove any exclusive options if regular option selected
            final exclusiveOptions = widget.component.options.where((o) => o.isExclusive);
            for (final ex in exclusiveOptions) {
              _selectedOptionIds.remove(ex.id);
            }
          }
          _selectedOptionIds.add(option.id);
        }
      });
    } else {
      setState(() {
        _selectedOptionIds.clear();
        _selectedOptionIds.add(option.id);
      });
      // Single-choice immediately continues workflow without restart
      widget.onOptionSelected?.call(option.copyWith(isSelected: true));
    }
  }

  void _submitMultiple() {
    final selected = widget.component.options
        .where((o) => _selectedOptionIds.contains(o.id))
        .map((o) => o.copyWith(isSelected: true))
        .toList();

    widget.onMultiOptionSubmitted?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.component.options;
    final prompt = widget.component.promptText ?? widget.component.title ?? 'Select an option:';

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isMultiSelect ? Icons.checklist_rounded : Icons.radio_button_checked_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedOptionIds.contains(option.id);

              return InkWell(
                onTap: () => _handleOptionTap(option),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.subtleTealSurface : AppColors.lightContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.lightBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMultiSelect
                            ? (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                            : (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                        color: isSelected ? AppColors.primary : AppColors.lightTextMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppColors.navy : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (option.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                option.subtitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isMultiSelect) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _selectedOptionIds.isEmpty ? null : _submitMultiple,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Continue (${_selectedOptionIds.length} selected)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.lightBorder,
                  disabledForegroundColor: AppColors.lightTextMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

