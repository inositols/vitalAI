import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import '../../data/models/patient_model.dart';

/// Screen listing patient profiles and allowing selection or creation.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  @override
  void initState() {
    super.initState();
    // Load patient profiles on entry
    context.read<PatientBloc>().add(PatientListRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who is tracking today?'),
        centerTitle: true,
      ),
      body: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientFailure) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (state is PatientLoadSuccess) {
            final patients = state.patients;

            if (patients.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Profiles Found',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a profile to start tracking health vitals.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Patient Profile'),
                        onPressed: () => _showAddPatientDialog(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final isActive = state.activePatient?.id == patient.id;

                        return InkWell(
                          onTap: () {
                            context.read<PatientBloc>().add(
                              PatientSelected(patient),
                            );
                            context.go('/');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            color: isActive
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surface,
                            borderOnForeground: true,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondaryContainer,
                                    child: Text(
                                      patient.name.isNotEmpty
                                          ? patient.name[0].toUpperCase()
                                          : 'P',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? theme.colorScheme.onPrimary
                                            : theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    patient.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${patient.gender} • ${DateTime.now().year - patient.dateOfBirth.year} yrs',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Patient Profile'),
                    onPressed: () => _showAddPatientDialog(context),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _AddPatientForm(
          onSave: (patient) {
            context.read<PatientBloc>().add(PatientSaved(patient));
            Navigator.pop(modalContext);
          },
        ),
      ),
    );
  }
}

class _AddPatientForm extends StatefulWidget {
  final Function(PatientModel) onSave;
  const _AddPatientForm({required this.onSave});

  @override
  State<_AddPatientForm> createState() => _AddPatientFormState();
}

class _AddPatientFormState extends State<_AddPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'Male';
  DateTime _dob = DateTime(1980, 1, 1);

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date of Birth'),
                subtitle: Text('${_dob.day}/${_dob.month}/${_dob.year}'),
                leading: const Icon(Icons.calendar_today_outlined),
                trailing: const Icon(Icons.arrow_drop_down),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
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
                      validator: (val) =>
                          val == null || double.tryParse(val) == null
                          ? 'Enter height'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      validator: (val) =>
                          val == null || double.tryParse(val) == null
                          ? 'Enter weight'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact (Name & Phone)',
                  prefixIcon: Icon(Icons.emergency_outlined),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Emergency contact required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Primary Doctor Name',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Doctor Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Medical Notes / Allergies',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final patient = PatientModel()
                      ..remoteId = const Uuid().v4()
                      ..name = _nameController.text.trim()
                      ..gender = _gender
                      ..dateOfBirth = _dob
                      ..height = double.parse(_heightController.text)
                      ..weight = double.parse(_weightController.text)
                      ..emergencyContact = _emergencyController.text.trim()
                      ..doctorName = _doctorNameController.text.trim()
                      ..doctorPhone = _doctorPhoneController.text.trim()
                      ..notes = _notesController.text.trim()
                      ..isSynced = false
                      ..updatedAt = DateTime.now();

                    widget.onSave(patient);
                  }
                },
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
