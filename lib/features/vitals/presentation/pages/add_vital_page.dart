import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../patients/data/models/patient_model.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../../data/models/vital_record.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/notifications/notification_service.dart';

class AddVitalPage extends StatefulWidget {
  const AddVitalPage({super.key});

  @override
  State<AddVitalPage> createState() => _AddVitalPageState();
}

class _AddVitalPageState extends State<AddVitalPage>
    with SingleTickerProviderStateMixin {
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

  void _save(PatientModel patient, SettingsState settings) {
    if (_formKey.currentState?.validate() ?? false) {
      double? temp = double.tryParse(_tempController.text);
      if (temp != null && settings.tempUnit == 'F') {
        temp = (temp - 32) * 5 / 9;
      }

      double? glucose = double.tryParse(_glucoseController.text);
      if (glucose != null && settings.glucoseUnit == 'mmol/L') {
        glucose = glucose * 18.018;
      }

      double? weight = double.tryParse(_weightController.text);
      if (weight != null && settings.weightUnit == 'lbs') {
        weight = weight / 2.20462;
      }

      double? bmi;
      if (weight != null && patient.height > 0) {
        final heightInMeters = patient.height / 100.0;
        bmi = weight / (heightInMeters * heightInMeters);
      }

      final record = VitalRecord()
        ..remoteId = const Uuid().v4()
        ..patientId = patient.id
        ..dateTime = DateTime.now()
        ..systolic = double.tryParse(_systolicController.text)
        ..diastolic = double.tryParse(_diastolicController.text)
        ..glucoseValue = glucose
        ..glucoseMealContext = _glucoseMealContext
        ..pulseRate = double.tryParse(_pulseController.text)
        ..oxygenSaturation = double.tryParse(_spo2Controller.text)
        ..bodyTemperature = temp
        ..weight = weight
        ..bmi = bmi
        ..note = _noteController.text.trim()
        ..deviceUsed = _deviceController.text.trim()
        ..tags = List.from(_tags)
        ..isSynced = false
        ..updatedAt = DateTime.now();

      // Dispatch to vitals BLoC
      context.read<VitalsBloc>().add(VitalsRecordSaved(record));

      // Trigger immediate success notification on the system bar
      locator<NotificationService>().showNotification(
        id: 2000,
        title: "Vitals Logged",
        body: "Health metrics successfully recorded.",
      );

      // Trigger adaptive notification checks (simulated directly here or in Repository)
      _checkAdaptiveAlerts(record);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals reading saved successfully.')),
      );
      context.go('/');
    }
  }

  void _checkAdaptiveAlerts(VitalRecord r) {
    final ns = locator<NotificationService>();

    // 1. Critical Emergency Alerts (Push/Local immediate notifications)
    if (r.systolic != null && r.systolic! >= 180) {
      ns.showNotification(
        id: 1001,
        title: "⚠️ Hypertensive Crisis Warning",
        body: "Your Systolic BP is high (${r.systolic} mmHg). Please seek medical help immediately.",
      );
    } else if (r.diastolic != null && r.diastolic! >= 120) {
      ns.showNotification(
        id: 1002,
        title: "⚠️ Hypertensive Crisis Warning",
        body: "Your Diastolic BP is high (${r.diastolic} mmHg). Please seek medical help immediately.",
      );
    } else if (r.oxygenSaturation != null && r.oxygenSaturation! < 90) {
      ns.showNotification(
        id: 1003,
        title: "⚠️ Low Oxygen Saturation",
        body: "Severe Hypoxia warning: SpO₂ is ${r.oxygenSaturation}%. Contact emergency care.",
      );
    } else if (r.glucoseValue != null && r.glucoseValue! > 300) {
      ns.showNotification(
        id: 1004,
        title: "⚠️ Severe Hyperglycemia Alert",
        body: "Glucose is high (${r.glucoseValue} mg/dL). Monitor symptoms and consult a doctor.",
      );
    } else if (r.glucoseValue != null && r.glucoseValue! < 50) {
      ns.showNotification(
        id: 1005,
        title: "⚠️ Hypoglycemia Warning",
        body: "Glucose is low (${r.glucoseValue} mg/dL). Consume fast-acting sugar and check again.",
      );
    } else if (r.bodyTemperature != null && r.bodyTemperature! > 40) {
      ns.showNotification(
        id: 1006,
        title: "⚠️ High Fever Warning",
        body: "Body temperature is ${r.bodyTemperature}°C. Consult a doctor.",
      );
    }

    // 2. Elevated BP Recheck reminder (scheduled in 30 mins)
    if (r.systolic != null && r.systolic! >= 135) {
      ns.scheduleBPRecheckReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess ||
            patientState.activePatient == null) {
          return const Scaffold(
            body: Center(child: Text("Please select a patient profile first.")),
          );
        }

        final patient = patientState.activePatient!;

        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final tempUnit = settingsState.tempUnit;
            final glucoseUnit = settingsState.glucoseUnit;
            final weightUnit = settingsState.weightUnit;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Log Vitals'),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withOpacity(0.08),
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                    0.6,
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.favorite_outline),
                      text: 'Blood Pressure',
                    ),
                    Tab(icon: Icon(Icons.opacity), text: 'Blood Glucose'),
                    Tab(icon: Icon(Icons.speed), text: 'Oxygen & Pulse'),
                    Tab(
                      icon: Icon(Icons.thermostat_outlined),
                      text: 'Temperature',
                    ),
                    Tab(icon: Icon(Icons.scale_outlined), text: 'Weight'),
                  ],
                ),
              ),
              body: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // BP Tab
                    _buildTabWrapper(
                      title: 'Blood Pressure',
                      subtitle: 'Log Systolic and Diastolic pressure.',
                      patient: patient,
                      settingsState: settingsState,
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
                                validator: (v) =>
                                    v != null &&
                                        v.isNotEmpty &&
                                        double.tryParse(v) == null
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
                                validator: (v) =>
                                    v != null &&
                                        v.isNotEmpty &&
                                        double.tryParse(v) == null
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
                      patient: patient,
                      settingsState: settingsState,
                      children: [
                        TextFormField(
                          controller: _glucoseController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Glucose Level ($glucoseUnit)',
                            hintText: glucoseUnit == 'mmol/L'
                                ? 'e.g. 5.3'
                                : 'e.g. 95',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _glucoseMealContext,
                          decoration: const InputDecoration(
                            labelText: 'Meal Context',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fasting',
                              child: Text('Fasting'),
                            ),
                            DropdownMenuItem(
                              value: 'random',
                              child: Text('Random'),
                            ),
                            DropdownMenuItem(
                              value: 'before_meal',
                              child: Text('Before Meal'),
                            ),
                            DropdownMenuItem(
                              value: 'after_meal',
                              child: Text('After Meal'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _glucoseMealContext = val);
                            }
                          },
                        ),
                      ],
                    ),
                    // SpO2 & Pulse Tab
                    _buildTabWrapper(
                      title: 'Oxygen & Pulse',
                      subtitle: 'Log SpO2 and pulse readings.',
                      patient: patient,
                      settingsState: settingsState,
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
                      patient: patient,
                      settingsState: settingsState,
                      children: [
                        TextFormField(
                          controller: _tempController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Temperature (°$tempUnit)',
                            hintText: tempUnit == 'F'
                                ? 'e.g. 98.0'
                                : 'e.g. 36.6',
                          ),
                        ),
                      ],
                    ),
                    // Weight Tab
                    _buildTabWrapper(
                      title: 'Weight Tracker',
                      subtitle: 'Log weight to calculate BMI.',
                      patient: patient,
                      settingsState: settingsState,
                      children: [
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight ($weightUnit)',
                            hintText: weightUnit == 'lbs'
                                ? 'e.g. 165'
                                : 'e.g. 75',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
    required PatientModel patient,
    required SettingsState settingsState,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Common Info Fields (Notes, Device used)
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
          const SizedBox(height: 24),
          // Save Action Button
          SpringTap(
            onTap: () => _save(patient, settingsState),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Save Vitals Record',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Spring tap scaling feedback helper
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SpringTap({super.key, required this.child, this.onTap});

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) {
        if (widget.onTap != null) {
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () => widget.onTap != null ? _controller.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
