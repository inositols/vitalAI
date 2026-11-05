import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_component.dart';

/// Contextual follow-up question card rendered when essential clinical or workflow info is missing.
class FollowUpCard extends StatefulWidget {
  final GenUiComponent component;
  final GenUiInputCallback? onAnswerSubmitted;
  final GenUiVoidCallback? onSkip;
  final GenUiVoidCallback? onCancel;

  const FollowUpCard({
    super.key,
    required this.component,
    this.onAnswerSubmitted,
    this.onSkip,
    this.onCancel,
  });

  @override
  State<FollowUpCard> createState() => _FollowUpCardState();
}

class _FollowUpCardState extends State<FollowUpCard> {
  late final TextEditingController _controller;
  String? _selectedChip;

  @override
  void initState() {
    super.initState();
    final initial = widget.component.data['initialValue']?.toString() ??
        widget.component.data['defaultValue']?.toString() ??
        '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isOptional => widget.component.data['isOptional'] == true || widget.component.data['optional'] == true;
  String get _targetField => widget.component.data['targetField']?.toString() ?? 'answer';
  String get _promptText =>
      widget.component.promptText ??
      widget.component.data['question']?.toString() ??
      widget.component.title ??
      'Please provide additional details:';
  String? get _unit => widget.component.data['unit']?.toString();
  String? get _helpText => widget.component.data['helpText']?.toString() ?? widget.component.subtitle;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && !_isOptional) return;

    widget.onAnswerSubmitted?.call({
      _targetField: text,
      'field': _targetField,
      'value': text,
    });
  }

  void _selectChip(String label, dynamic value) {
    setState(() {
      _selectedChip = label;
      _controller.text = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final predefinedChoices = (widget.component.data['choices'] as List?) ??
        (widget.component.data['options'] as List?) ??
        widget.component.options.map((o) => {'label': o.label, 'value': o.value}).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
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
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _promptText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          if (_helpText != null) ...[
            const SizedBox(height: 6),
            Text(
              _helpText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
          if (predefinedChoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: predefinedChoices.map((choice) {
                final label = (choice is Map) ? (choice['label']?.toString() ?? '') : choice.toString();
                final val = (choice is Map) ? (choice['value'] ?? label) : label;
                final isSelected = _selectedChip == label;

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => _selectChip(label, val),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.lightContainer,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.lightTextPrimary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Type answer here...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.lightTextMuted),
                    suffixText: _unit,
                    suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: AppColors.lightBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
                ),
              if (_isOptional && widget.onSkip != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.onSkip,
                  icon: const Icon(Icons.skip_next_rounded, size: 16),
                  label: const Text('Skip (Optional)', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

