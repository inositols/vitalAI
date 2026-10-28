import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/patient_draft.dart';
import '../../data/models/patient_model.dart';

/// Interactive conversational GenUI card for adaptive patient creation.
/// Renders the focused follow-up question for the active step, allowing
/// the provider to answer via tap/touch, type, or voice.
class ConversationalPatientCreationCard extends StatefulWidget {
  final PatientDraft draft;
  final ValueChanged<String> onSubmitUtterance;
  final VoidCallback onSkip;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onProceedAnyway;
  final ValueChanged<PatientModel>? onOpenPatient;
  final ValueChanged<PatientModel>? onRecordVitals;

  const ConversationalPatientCreationCard({
    super.key,
    required this.draft,
    required this.onSubmitUtterance,
    required this.onSkip,
    required this.onCancel,
    required this.onEdit,
    required this.onConfirm,
    required this.onProceedAnyway,
    this.onOpenPatient,
    this.onRecordVitals,
  });

  @override
  State<ConversationalPatientCreationCard> createState() => _ConversationalPatientCreationCardState();
}

class _ConversationalPatientCreationCardState extends State<ConversationalPatientCreationCard> {
  late TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void didUpdateWidget(ConversationalPatientCreationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.currentStep != widget.draft.currentStep) {
      _inputController.clear();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = widget.draft;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: draft.currentStep == PatientCreationStep.completed
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: draft.currentStep == PatientCreationStep.completed ? 1.5 : 1.0,
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
          // Header: Category, Progress & Cancel Action
          _buildHeader(isDark),

          // Main Step Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildStepContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final draft = widget.draft;
    String stepLabel = '';
    double progress = 0.2;

    switch (draft.currentStep) {
      case PatientCreationStep.name:
        stepLabel = 'Step 1 of 4 • Full Name (Required)';
        progress = 0.25;
        break;
      case PatientCreationStep.dateOfBirth:
        stepLabel = 'Step 2 of 4 • Date of Birth';
        progress = 0.50;
        break;
      case PatientCreationStep.phone:
        stepLabel = 'Step 3 of 4 • Phone Number';
        progress = 0.75;
        break;
      case PatientCreationStep.email:
        stepLabel = 'Step 4 of 4 • Email Address';
        progress = 0.90;
        break;
      case PatientCreationStep.gender:
        stepLabel = 'Clinical Profile • Biological Sex';
        progress = 0.95;
        break;
      case PatientCreationStep.duplicateWarning:
        stepLabel = 'Discreet Duplicate Check';
        progress = 0.95;
        break;
      case PatientCreationStep.review:
        stepLabel = 'Ready for Confirmation';
        progress = 1.0;
        break;
      case PatientCreationStep.completed:
        stepLabel = 'Registration Complete';
        progress = 1.0;
        break;
      case PatientCreationStep.cancelled:
        stepLabel = 'Cancelled';
        progress = 0.0;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Patient Registration',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              if (draft.currentStep != PatientCreationStep.completed &&
                  draft.currentStep != PatientCreationStep.cancelled)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Cancel registration',
                  onPressed: widget.onCancel,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  stepLabel,
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              if (draft.currentStep != PatientCreationStep.completed &&
                  draft.currentStep != PatientCreationStep.cancelled)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.labelSmall(
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    final draft = widget.draft;

    switch (draft.currentStep) {
      case PatientCreationStep.name:
        return _buildNameInput(isDark);
      case PatientCreationStep.dateOfBirth:
        return _buildDateOfBirthInput(isDark);
      case PatientCreationStep.phone:
        return _buildPhoneInput(isDark);
      case PatientCreationStep.email:
        return _buildEmailInput(isDark);
      case PatientCreationStep.gender:
        return _buildGenderSelection(isDark);
      case PatientCreationStep.duplicateWarning:
        return _buildDuplicateWarning(isDark);
      case PatientCreationStep.review:
        return _buildReviewCard(isDark);
      case PatientCreationStep.completed:
        return _buildCompletedCard(isDark);
      case PatientCreationStep.cancelled:
        return _buildCancelledCard(isDark);
    }
  }

  // Step 1: Full Name Input
  Widget _buildNameInput(bool isDark) {
    final error = widget.draft.validationErrors['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What is the patient's full name?",
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Speak or type the patient name to start.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Chika Okafor',
            prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              widget.onSubmitUtterance(val.trim());
            }
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final val = _inputController.text.trim();
              if (val.isNotEmpty) {
                widget.onSubmitUtterance(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // Step 2: Date of Birth Input
  Widget _buildDateOfBirthInput(bool isDark) {
    final firstName = widget.draft.name?.split(' ').first ?? 'the patient';
    final error = widget.draft.validationErrors['dateOfBirth'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What is $firstName's date of birth?",
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Speak, pick a date, or tap Skip if not immediately available.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(error, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Quick Age Preset Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip('25 yrs old', () => _selectRelativeAge(25)),
            _buildPresetChip('35 yrs old', () => _selectRelativeAge(35)),
            _buildPresetChip('50 yrs old', () => _selectRelativeAge(50)),
            _buildPresetChip('65 yrs old', () => _selectRelativeAge(65)),
          ],
        ),
        const SizedBox(height: 12),

        // Date Picker Action Button
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
          label: const Text('Select from Calendar', style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.lightBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final formatted = '${picked.day} ${_monthName(picked.month)} ${picked.year}';
              widget.onSubmitUtterance(formatted);
            }
          },
        ),
        const SizedBox(height: 8),

        // Skip Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip (Optional)', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  void _selectRelativeAge(int age) {
    final now = DateTime.now();
    final dob = DateTime(now.year - age, now.month, now.day);
    widget.onSubmitUtterance('${dob.day} ${_monthName(dob.month)} ${dob.year}');
  }

  // Step 3: Phone Number Input
  Widget _buildPhoneInput(bool isDark) {
    final firstName = widget.draft.name?.split(' ').first ?? 'the patient';
    final error = widget.draft.validationErrors['phone'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What is $firstName's phone number?",
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Speak or type phone number, or say "I don\'t have it yet" to skip.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'e.g. +234 803 123 4567',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              widget.onSubmitUtterance(val.trim());
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.slate,
                  side: const BorderSide(color: AppColors.lightBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("I don't have it yet (Skip)"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final val = _inputController.text.trim();
                  if (val.isNotEmpty) {
                    widget.onSubmitUtterance(val);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save Phone'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: Email Input
  Widget _buildEmailInput(bool isDark) {
    final firstName = widget.draft.name?.split(' ').first ?? 'the patient';
    final error = widget.draft.validationErrors['email'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Would you like to add an email address?",
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Email for $firstName is optional and can be updated anytime.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'e.g. chika.okafor@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              widget.onSubmitUtterance(val.trim());
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.slate,
                  side: const BorderSide(color: AppColors.lightBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Skip Email'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final val = _inputController.text.trim();
                  if (val.isNotEmpty) {
                    widget.onSubmitUtterance(val);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save Email'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: Gender / Biological Sex Selection
  Widget _buildGenderSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What is the patient's biological sex?",
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Used for sex-adjusted clinical reference ranges.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildChoiceChip('Female', Icons.female, () => widget.onSubmitUtterance('Female')),
            _buildChoiceChip('Male', Icons.male, () => widget.onSubmitUtterance('Male')),
            _buildChoiceChip('Other', Icons.transgender, () => widget.onSubmitUtterance('Other')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip (Unspecified)', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  // Duplicate Warning Discreet Card
  Widget _buildDuplicateWarning(bool isDark) {
    final dup = widget.draft.potentialDuplicate!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                'Possible Existing Patient Found',
                style: AppTypography.titleSmall(color: const Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A patient matching these details already exists in your records:',
            style: AppTypography.bodySmall(color: const Color(0xFF78350F)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    dup.name.isNotEmpty ? dup.name[0] : 'P',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dup.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${dup.remoteId} • ${(dup.phone ?? dup.emergencyContact)}', style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onOpenPatient?.call(dup);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Open Existing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onProceedAnyway,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create New Anyway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Review Summary Card
  Widget _buildReviewCard(bool isDark) {
    final draft = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Patient Record',
          style: AppTypography.titleMedium(color: isDark ? Colors.white : AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Please verify the clinical details before saving.',
          style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),

        // Review Details Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildReviewRow('Full Name', draft.name ?? 'Unspecified', isBold: true),
              const Divider(height: 16),
              _buildReviewRow(
                'Date of Birth',
                draft.dateOfBirth != null
                    ? '${draft.dateOfBirth!.day} ${_monthName(draft.dateOfBirth!.month)} ${draft.dateOfBirth!.year} (${draft.age} yrs)'
                    : 'Not specified',
              ),
              const Divider(height: 16),
              _buildReviewRow('Phone Number', draft.phone ?? 'Not specified'),
              const Divider(height: 16),
              _buildReviewRow('Email Address', draft.email ?? 'Not specified'),
              const Divider(height: 16),
              _buildReviewRow('Biological Sex', draft.gender ?? 'Unspecified'),
            ],
          ),
        ),
        if (draft.lastError != null) ...[
          const SizedBox(height: 8),
          Text(draft.lastError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
        ],
        const SizedBox(height: 16),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: draft.isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, color: Colors.white),
            label: Text(
              draft.isSaving ? 'Saving Patient Record...' : 'Confirm and Create Patient',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: draft.isSaving ? null : widget.onConfirm,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.slate),
                label: const Text('Edit Details', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
                onPressed: widget.onEdit,
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                label: const Text('Cancel', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                onPressed: widget.onCancel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Registration Completed Card
  Widget _buildCompletedCard(bool isDark) {
    final patient = widget.draft.createdPatient ?? widget.draft.toPatientModel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient Created Successfully', style: AppTypography.titleMedium(color: AppColors.primary)),
                  Text(
                    '${patient.name} • ${patient.remoteId}',
                    style: AppTypography.bodySmall(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Open Patient'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => widget.onOpenPatient?.call(patient),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.favorite_outline, size: 18, color: Colors.white),
                label: const Text('Record Vitals', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => widget.onRecordVitals?.call(patient),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Cancelled State Card
  Widget _buildCancelledCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.slate, size: 20),
            const SizedBox(width: 8),
            Text('Registration Cancelled', style: AppTypography.titleSmall(color: AppColors.slate)),
          ],
        ),
        const SizedBox(height: 4),
        Text('No patient record was saved.', style: AppTypography.bodySmall(color: AppColors.slate)),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }
}
