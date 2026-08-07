import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/patient_model.dart';

class PatientFormModal extends StatefulWidget {
  final PatientModel? patient;
  final Function(PatientModel patient) onSave;

  const PatientFormModal({
    super.key,
    this.patient,
    required this.onSave,
  });

  @override
  State<PatientFormModal> createState() => _PatientFormModalState();
}

class _PatientFormModalState extends State<PatientFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _contactController;
  String _gender = 'Male';
  late DateTime _dob;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dob = widget.patient?.dateOfBirth ?? now.subtract(const Duration(days: 365 * 30));

    int calculatedAge = now.year - _dob.year;
    if (now.month < _dob.month || (now.month == _dob.month && now.day < _dob.day)) {
      calculatedAge--;
    }
    if (calculatedAge < 0) calculatedAge = 30;

    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _ageController = TextEditingController(text: calculatedAge.toString());
    _heightController = TextEditingController(
      text: widget.patient != null ? widget.patient!.height.toStringAsFixed(0) : '170',
    );
    _weightController = TextEditingController(
      text: widget.patient != null ? widget.patient!.weight.toStringAsFixed(0) : '70',
    );
    _contactController = TextEditingController(
      text: widget.patient?.emergencyContact ?? '',
    );

    if (widget.patient != null) {
      _gender = widget.patient!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        int age = now.year - picked.year;
        if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _ageController.text = (age < 0 ? 0 : age).toString();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final p = widget.patient ?? PatientModel();
      if (widget.patient == null) {
        p.remoteId = const Uuid().v4();
      }

      final parsedAge = int.tryParse(_ageController.text.trim()) ?? 30;
      final now = DateTime.now();

      p.dateOfBirth = DateTime(now.year - parsedAge, _dob.month, _dob.day);
      p.name = _nameController.text.trim();
      p.gender = _gender;
      p.height = double.tryParse(_heightController.text.trim()) ?? 170.0;
      p.weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
      p.emergencyContact = _contactController.text.trim();
      p.isSynced = false;
      p.updatedAt = DateTime.now();

      widget.onSave(p);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Eleanor Vance',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _buildAgeAndGenderRow(),
              const SizedBox(height: 14),
              _buildHeightAndWeightRow(),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Emergency Phone Contact',
                  hintText: '+1 555 019 2831',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          widget.patient != null ? 'Edit Patient Profile' : 'Add New Patient Profile',
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildAgeAndGenderRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Age (Years)',
              hintText: '35',
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                tooltip: 'Pick Date of Birth',
                onPressed: _pickDateOfBirth,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Age required';
              final num = int.tryParse(val.trim());
              if (num == null || num < 0 || num > 120) return 'Invalid age';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded)),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Female', child: Text('Female', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _gender = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeightAndWeightRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Height (cm)', hintText: '170', prefixIcon: Icon(Icons.height_rounded)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: '70', prefixIcon: Icon(Icons.monitor_weight_outlined)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Save Profile',
            onPressed: _submit,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }
}
