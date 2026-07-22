import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/extensions/build_context_ext.dart';
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
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _contactController;
  String _gender = 'Male';
  DateTime _dob = DateTime.now().subtract(const Duration(days: 365 * 30));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _heightController = TextEditingController(
      text: widget.patient != null ? widget.patient!.height.toString() : '170',
    );
    _weightController = TextEditingController(
      text: widget.patient != null ? widget.patient!.weight.toString() : '70',
    );
    _contactController = TextEditingController(
      text: widget.patient?.emergencyContact ?? '',
    );

    if (widget.patient != null) {
      _gender = widget.patient!.gender;
      _dob = widget.patient!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final p = widget.patient ?? PatientModel();
      if (widget.patient == null) {
        p.remoteId = const Uuid().v4();
      }

      p.name = _nameController.text.trim();
      p.gender = _gender;
      p.dateOfBirth = _dob;
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
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.patient != null ? 'Edit Profile' : 'Add New Patient Profile',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
