import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';

/// Structured editable card representing extracted patient registration and clinical draft info.
class EditablePatientCard extends StatefulWidget {
  final GenUiComponent component;
  final GenUiInputCallback? onUpdateFields;
  final GenUiActionCallback? onActionSelected;
  final GenUiVoidCallback? onConfirmSave;
  final GenUiVoidCallback? onCancel;

  const EditablePatientCard({
    super.key,
    required this.component,
    this.onUpdateFields,
    this.onActionSelected,
    this.onConfirmSave,
    this.onCancel,
  });

  @override
  State<EditablePatientCard> createState() => _EditablePatientCardState();
}

class _EditablePatientCardState extends State<EditablePatientCard> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _complaintController;
  late final TextEditingController _durationController;
  late final TextEditingController _bpController;

  @override
  void initState() {
    super.initState();
    final data = widget.component.data;
    _nameController = TextEditingController(text: data['name']?.toString() ?? '');
    _ageController = TextEditingController(text: data['age']?.toString() ?? '');
    _complaintController = TextEditingController(text: data['complaint']?.toString() ?? data['chiefComplaint']?.toString() ?? '');
    _durationController = TextEditingController(text: data['duration']?.toString() ?? '');
    _bpController = TextEditingController(text: data['bloodPressure']?.toString() ?? data['bp']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _complaintController.dispose();
    _durationController.dispose();
    _bpController.dispose();
    super.dispose();
  }

  void _saveEdits() {
    setState(() => _isEditing = false);
    widget.onUpdateFields?.call({
      'name': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'complaint': _complaintController.text.trim(),
      'duration': _durationController.text.trim(),
      'bloodPressure': _bpController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.component.data;
    final name = data['name']?.toString().trim();
    final age = data['age']?.toString().trim();
    final complaint = data['complaint']?.toString().trim() ?? data['chiefComplaint']?.toString().trim();
    final duration = data['duration']?.toString().trim();
    final bp = data['bloodPressure']?.toString().trim() ?? data['bp']?.toString().trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.badge_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Patient Information (Draft)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: _isEditing ? 'Save Edits' : 'Edit Information',
                onPressed: () {
                  if (_isEditing) {
                    _saveEdits();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.lightBorder),
          if (!_isEditing) ...[
            _buildFieldRow('Name', name),
            _buildFieldRow('Age', age != null && age.isNotEmpty ? '$age years' : null),
            _buildFieldRow('Complaint', complaint),
            _buildFieldRow('Duration', duration),
            _buildFieldRow('Blood Pressure', bp != null && bp.isNotEmpty ? '$bp mmHg' : null),
          ] else ...[
            _buildEditField('Name', _nameController),
            const SizedBox(height: 8),
            _buildEditField('Age (years)', _ageController, isNumeric: true),
            const SizedBox(height: 8),
            _buildEditField('Complaint', _complaintController),
            const SizedBox(height: 8),
            _buildEditField('Duration', _durationController),
            const SizedBox(height: 8),
            _buildEditField('Blood Pressure (e.g. 118/76)', _bpController),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveEdits,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Apply Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Action Buttons: Edit, Add More, Confirm & Save, Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel ?? () {
                    widget.onActionSelected?.call(const GenUiAction(
                      id: 'cancel_patient_creation',
                      type: GenUiActionType.cancelWorkflow,
                      label: 'Cancel',
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lightTextSecondary,
                    side: const BorderSide(color: AppColors.lightBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onActionSelected?.call(const GenUiAction(
                      id: 'add_more_info',
                      type: GenUiActionType.addInformation,
                      label: 'Add More Information',
                    ));
                  },
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Add More', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: widget.onConfirmSave ?? () {
                    widget.onActionSelected?.call(const GenUiAction(
                      id: 'confirm_save_patient',
                      type: GenUiActionType.confirmSave,
                      label: 'Confirm & Save',
                    ));
                  },
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Confirm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String? value) {
    final hasValue = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value : 'Not provided',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? AppColors.navy : AppColors.lightTextMuted,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13, color: AppColors.navy),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
            filled: true,
            fillColor: AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
          ),
        ),
      ],
    );
  }
}

