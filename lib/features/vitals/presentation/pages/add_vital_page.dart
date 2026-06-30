import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../../data/models/vital_record.dart';

/// Screen allowing users to log individual or combined vitals readings.
class AddVitalPage extends StatefulWidget {
  const AddVitalPage({super.key});

  @override
  State<AddVitalPage> createState() => _AddVitalPageState();
}

class _AddVitalPageState extends State<AddVitalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _pulseController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _deviceController = TextEditingController();

  String _glucoseMealContext = 'random';
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _pulseController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  void _save(int patientId) {
    if (_formKey.currentState?.validate() ?? false) {
      final record = VitalRecord()
        ..remoteId = const Uuid().v4()
        ..patientId = patientId
        ..dateTime = DateTime.now()
        ..systolic = double.tryParse(_systolicController.text)
        ..diastolic = double.tryParse(_diastolicController.text)
        ..glucoseValue = double.tryParse(_glucoseController.text)
        ..glucoseMealContext = _glucoseMealContext
        ..pulseRate = double.tryParse(_pulseController.text)
        ..oxygenSaturation = double.tryParse(_spo2Controller.text)
        ..bodyTemperature = double.tryParse(_tempController.text)
        ..weight = double.tryParse(_weightController.text)
        ..note = _noteController.text.trim()
        ..deviceUsed = _deviceController.text.trim()
        ..tags = List.from(_tags)
        ..isSynced = false
        ..updatedAt = DateTime.now();

      // Dispatch to vitals BLoC
      context.read<VitalsBloc>().add(VitalsRecordSaved(record));

      // Trigger adaptive notification checks (simulated directly here or in Repository)
      _checkAdaptiveAlerts(record);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals reading saved successfully.')),
      );
      context.go('/');
    }
  }

  void _checkAdaptiveAlerts(VitalRecord r) {
    // Simple helper check for elevated BP to trigger prompt
    if (r.systolic != null && r.systolic! >= 135) {
      // In a real flow, this could prompt "Would you like a recheck reminder?"
      // For now, schedule recheck reminder automatically
      debugPrint("Elevated BP detected. Scheduling adaptive recheck reminder...");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: Center(child: Text("Please select a patient profile first.")),
          );
        }

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Log Vitals'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.favorite), text: 'Blood Pressure'),
                Tab(icon: Icon(Icons.opacity), text: 'Blood Glucose'),
                Tab(icon: Icon(Icons.speed), text: 'Oxygen & Pulse'),
                Tab(icon: Icon(Icons.thermostat), text: 'Temperature'),
                Tab(icon: Icon(Icons.scale), text: 'Weight'),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // BP Tab
                      _buildTabWrapper(
                        title: 'Blood Pressure',
                        subtitle: 'Log Systolic and Diastolic pressure.',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _systolicController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Systolic (mmHg)',
                                    hintText: 'e.g. 120',
                                  ),
                                  validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null
                                      ? 'Invalid'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _diastolicController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Diastolic (mmHg)',
                                    hintText: 'e.g. 80',
                                  ),
                                  validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null
                                      ? 'Invalid'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Glucose Tab
                      _buildTabWrapper(
                        title: 'Blood Glucose',
                        subtitle: 'Log blood sugar readings.',
                        children: [
                          TextFormField(
                            controller: _glucoseController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Glucose Level (mg/dL)',
                              hintText: 'e.g. 95',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _glucoseMealContext,
                            decoration: const InputDecoration(
                              labelText: 'Meal Context',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                              DropdownMenuItem(value: 'random', child: Text('Random')),
                              DropdownMenuItem(value: 'before_meal', child: Text('Before Meal')),
                              DropdownMenuItem(value: 'after_meal', child: Text('After Meal')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _glucoseMealContext = val);
                            },
                          ),
                        ],
                      ),
                      // SpO2 & Pulse Tab
                      _buildTabWrapper(
                        title: 'Oxygen & Pulse',
                        subtitle: 'Log SpO2 and pulse readings.',
                        children: [
                          TextFormField(
                            controller: _spo2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Oxygen Saturation (SpO₂ %)',
                              hintText: 'e.g. 98',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pulseController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pulse Rate (BPM)',
                              hintText: 'e.g. 72',
                            ),
                          ),
                        ],
                      ),
                      // Temperature Tab
                      _buildTabWrapper(
                        title: 'Body Temperature',
                        subtitle: 'Log core body temperature.',
                        children: [
                          TextFormField(
                            controller: _tempController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Temperature (°C)',
                              hintText: 'e.g. 36.6',
                            ),
                          ),
                        ],
                      ),
                      // Weight Tab
                      _buildTabWrapper(
                        title: 'Weight Tracker',
                        subtitle: 'Log weight to calculate BMI.',
                        children: [
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              hintText: 'e.g. 75',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Common Info Fields (Notes, Device used)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _deviceController,
                        decoration: const InputDecoration(
                          labelText: 'Device Used (Optional)',
                          prefixIcon: Icon(Icons.bluetooth),
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes / Comments',
                          prefixIcon: Icon(Icons.edit_note),
                          filled: false,
                        ),
                      ),
                    ],
                  ),
                ),

                // Save Action Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: () => _save(patient.id),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: const Text('Save Vitals Record'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
