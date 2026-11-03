import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../../../features/patients/data/models/patient_model.dart';
import '../models/conversation_intent.dart';
import '../models/conversation_workflow_state.dart';
import '../models/follow_up_question.dart';
import '../models/genui_question_type.dart';

/// Unified Adaptive GenUI follow-up card rendering the appropriate interactive
/// component based on the follow-up question type.
class AdaptiveGenUiFollowUpCard extends StatefulWidget {
  final FollowUpQuestion question;
  final ConversationWorkflowState state;
  final ValueChanged<dynamic> onAnswer;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const AdaptiveGenUiFollowUpCard({
    super.key,
    required this.question,
    required this.state,
    required this.onAnswer,
    required this.onConfirm,
    required this.onCancel,
    required this.onSkip,
    required this.onBack,
  });

  @override
  State<AdaptiveGenUiFollowUpCard> createState() => _AdaptiveGenUiFollowUpCardState();
}

class _AdaptiveGenUiFollowUpCardState extends State<AdaptiveGenUiFollowUpCard> {
  late TextEditingController _textController;
  final Set<String> _selectedMultiValues = {};

  @override
  void initState() {
    super.initState();
    final init = widget.question.initialValue;
    _textController = TextEditingController(text: init != null ? init.toString() : '');
  }

  @override
  void didUpdateWidget(AdaptiveGenUiFollowUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      final init = widget.question.initialValue;
      _textController.text = init != null ? init.toString() : '';
      _selectedMultiValues.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = widget.question;
    final hasError = widget.state.validationErrors.containsKey(question.targetField);
    final errorText = widget.state.validationErrors[question.targetField];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (question.questionType == GenUiQuestionType.confirmationCard
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: question.questionType == GenUiQuestionType.confirmationCard ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Title & Action controls
          _buildCardHeader(isDark),

          // Question Prompt & Help text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.promptText,
                  style: AppTypography.titleMedium(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                if (question.helpText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    question.helpText!,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Body: Render specialized interactive component
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildComponentBody(isDark),
          ),

          // Validation Error Banner if present
          if (hasError && errorText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: AppTypography.labelSmall(color: AppColors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(bool isDark) {
    final intent = widget.state.intent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(intent.icon, size: 13, color: AppColors.onPrimaryContainer),
                const SizedBox(width: 6),
                Text(
                  intent.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (widget.question.isOptional)
            TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Skip', style: TextStyle(fontSize: 12, color: AppColors.slate)),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Cancel workflow',
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentBody(bool isDark) {
    switch (widget.question.questionType) {
      case GenUiQuestionType.singleChoice:
      case GenUiQuestionType.ambiguousChoices:
        return _buildSingleChoiceList(isDark);

      case GenUiQuestionType.yesNo:
        return _buildYesNoButtons(isDark);

      case GenUiQuestionType.datePicker:
        return _buildDatePickerChips(isDark);

      case GenUiQuestionType.patientSelection:
        return _buildPatientCardsList(isDark);

      case GenUiQuestionType.multiSelect:
        return _buildMultiSelectChips(isDark);

      case GenUiQuestionType.numericInput:
        return _buildNumericInputField(isDark);

      case GenUiQuestionType.textInput:
        return _buildTextInputField(isDark);

      case GenUiQuestionType.previewCard:
        return _buildPreviewCard(isDark);

      case GenUiQuestionType.confirmationCard:
        return _buildConfirmationCard(isDark);
    }
  }

  // 1. Single Choice Options (Cards & Chips)
  Widget _buildSingleChoiceList(bool isDark) {
    final options = widget.question.options;
    return Column(
      children: options.map((opt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => widget.onAnswer(opt.value),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: opt.isRecommended
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : (isDark ? AppColors.darkCard : AppColors.lightContainer),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: opt.isRecommended
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  if (opt.icon != null) ...[
                    Icon(
                      opt.icon,
                      size: 18,
                      color: opt.isRecommended ? AppColors.primary : AppColors.slate,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              opt.label,
                              style: AppTypography.titleSmall(
                                color: isDark ? Colors.white : AppColors.secondary,
                              ),
                            ),
                            if (opt.isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Recommended',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (opt.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            opt.subtitle!,
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.slate),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. Yes/No Buttons
  Widget _buildYesNoButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => widget.onAnswer(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Text('No, Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.slate)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => widget.onAnswer(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Proceed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // 3. Date Picker Chips
  Widget _buildDatePickerChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
          label: const Text('Today'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
          onPressed: () => widget.onAnswer(DateTime.now()),
        ),
        ActionChip(
          avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
          label: const Text('Yesterday'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
          onPressed: () => widget.onAnswer(DateTime.now().subtract(const Duration(days: 1))),
        ),
        ActionChip(
          avatar: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
          label: const Text('Select Specific Date...'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              widget.onAnswer(picked);
            }
          },
        ),
      ],
    );
  }

  // 4. Patient Cards List
  Widget _buildPatientCardsList(bool isDark) {
    final options = widget.question.options;
    return Column(
      children: options.map((opt) {
        final patient = opt.metadata['patient'] as PatientModel?;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => widget.onAnswer(opt.value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      patient != null && patient.name.isNotEmpty
                          ? patient.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
                          : 'P',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: AppTypography.titleSmall(
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        if (opt.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            opt.subtitle!,
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Multi-Select Chips
  Widget _buildMultiSelectChips(bool isDark) {
    final options = widget.question.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = _selectedMultiValues.contains(opt.value.toString());
            return FilterChip(
              label: Text(opt.label),
              selected: isSelected,
              selectedColor: AppColors.primaryContainer,
              checkmarkColor: AppColors.primary,
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMultiValues.add(opt.value.toString());
                  } else {
                    _selectedMultiValues.remove(opt.value.toString());
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _selectedMultiValues.isNotEmpty
              ? () => widget.onAnswer(_selectedMultiValues.toList())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Apply Selection', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // 6. Numeric Input Field with Unit
  Widget _buildNumericInputField(bool isDark) {
    final unit = widget.question.unit ?? '';
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white : AppColors.secondary),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              hintText: 'e.g. ${widget.question.initialValue ?? 120}',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (val) {
              final parsed = double.tryParse(val.trim());
              if (parsed != null) widget.onAnswer(parsed);
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(_textController.text.trim());
            if (val != null) widget.onAnswer(val);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  // 7. Text Input Field
  Widget _buildTextInputField(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          maxLines: 3,
          minLines: 1,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.secondary),
          decoration: InputDecoration(
            hintText: widget.question.helpText ?? 'Enter text...',
            filled: true,
            fillColor: isDark ? AppColors.darkCard : AppColors.lightContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) widget.onAnswer(text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // 8. Preview Card (e.g. Clinical Note preview)
  Widget _buildPreviewCard(bool isDark) {
    final meta = widget.question.metadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    meta['visitType']?.toString() ?? 'Encounter Note',
                    style: AppTypography.titleSmall(color: isDark ? Colors.white : AppColors.secondary),
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                meta['content']?.toString() ?? '',
                style: AppTypography.bodyMedium(color: isDark ? Colors.white70 : AppColors.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Author: ${meta['authorName'] ?? 'Dr. Adeyemi'} • ${meta['patientName'] ?? 'Patient'}',
                style: AppTypography.labelSmall(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm & Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 9. Explicit Confirmation Card (Consequential Actions)
  Widget _buildConfirmationCard(bool isDark) {
    final meta = widget.question.metadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Ready to Commit Record',
                    style: AppTypography.titleSmall(color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...meta.entries.map((entry) {
                if (entry.value == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.secondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : AppColors.secondaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit Details'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm & Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
