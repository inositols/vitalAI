import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../patients/data/models/patient_model.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../../data/models/vital_record.dart';
import '../widgets/vital_input_fields.dart';

class AddVitalPage extends StatefulWidget {
  const AddVitalPage({super.key});

  @override
  State<AddVitalPage> createState() => _AddVitalPageState();
}

class _AddVitalPageState extends State<AddVitalPage> {
  int _activeMetricIndex = 0;

  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _pulseController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  String _glucoseMealContext = 'fasting';

  final List<Map<String, dynamic>> _metrics = const [
    {'title': 'Blood Pressure', 'short': 'BP', 'color': AppColors.bpVital},
    {'title': 'Blood Glucose', 'short': 'Glucose', 'color': AppColors.glucoseVital},
    {'title': 'Oxygen Saturation', 'short': 'SpO₂', 'color': AppColors.spo2Vital},
    {'title': 'Heart Rate', 'short': 'Pulse', 'color': AppColors.pulseVital},
    {'title': 'Body Temp', 'short': 'Temp', 'color': AppColors.tempVital},
    {'title': 'Body Weight', 'short': 'Weight', 'color': AppColors.weightVital},
  ];

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _pulseController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save(PatientModel patient, SettingsState settings) {
    // Validate that user entered data for selected metric
    if (_activeMetricIndex == 0 && (_systolicController.text.trim().isEmpty || _diastolicController.text.trim().isEmpty)) {
      context.showSnackBar('Please enter both systolic and diastolic blood pressure values');
      return;
    }
    if (_activeMetricIndex == 1 && _glucoseController.text.trim().isEmpty) {
      context.showSnackBar('Please enter a glucose measurement');
      return;
    }
    if (_activeMetricIndex == 2 && _spo2Controller.text.trim().isEmpty) {
      context.showSnackBar('Please enter oxygen saturation (SpO₂)');
      return;
    }
    if (_activeMetricIndex == 3 && _pulseController.text.trim().isEmpty) {
      context.showSnackBar('Please enter heart rate (BPM)');
      return;
    }
    if (_activeMetricIndex == 4 && _tempController.text.trim().isEmpty) {
      context.showSnackBar('Please enter body temperature');
      return;
    }
    if (_activeMetricIndex == 5 && _weightController.text.trim().isEmpty) {
      context.showSnackBar('Please enter body weight');
      return;
    }

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
      ..systolic = _activeMetricIndex == 0 ? double.tryParse(_systolicController.text) : null
      ..diastolic = _activeMetricIndex == 0 ? double.tryParse(_diastolicController.text) : null
      ..glucoseValue = _activeMetricIndex == 1 ? glucose : null
      ..glucoseMealContext = _activeMetricIndex == 1 ? _glucoseMealContext : null
      ..oxygenSaturation = _activeMetricIndex == 2 ? double.tryParse(_spo2Controller.text) : null
      ..pulseRate = (_activeMetricIndex == 0 || _activeMetricIndex == 2 || _activeMetricIndex == 3)
          ? double.tryParse(_pulseController.text)
          : null
      ..bodyTemperature = _activeMetricIndex == 4 ? temp : null
      ..weight = _activeMetricIndex == 5 ? weight : null
      ..bmi = _activeMetricIndex == 5 ? bmi : null
      ..note = _noteController.text.trim()
      ..isSynced = false
      ..updatedAt = DateTime.now();

    context.read<VitalsBloc>().add(VitalsRecordSaved(record));
    context.showSnackBar('✓ Vital reading recorded successfully');
    context.go('/charts');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final isDark = context.isDarkMode;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: AppEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No Active Patient',
              message: 'Select a patient profile before logging readings.',
            ),
          );
        }

        final patient = patientState.activePatient!;
        final activeMetric = _metrics[_activeMetricIndex];
        final Color activeColor = activeMetric['color'] as Color;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.go('/charts'),
            ),
            title: const Text('Log Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Patient Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Patient: ${patient.name}',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Metric Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_metrics.length, (index) {
                        final m = _metrics[index];
                        final isSelected = index == _activeMetricIndex;
                        final color = m['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(m['short'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _activeMetricIndex = index);
                            },
                            selectedColor: color,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? color : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Metric Input Card
                  AppCard(
                    padding: const EdgeInsets.all(24.0),
                    child: VitalInputFields(
                      activeTabIndex: _activeMetricIndex,
                      systolicController: _systolicController,
                      diastolicController: _diastolicController,
                      glucoseController: _glucoseController,
                      pulseController: _pulseController,
                      spo2Controller: _spo2Controller,
                      tempController: _tempController,
                      weightController: _weightController,
                      glucoseMealContext: _glucoseMealContext,
                      onGlucoseMealContextChanged: (val) => setState(() => _glucoseMealContext = val),
                      settings: settings,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional Clinical Notes
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Clinical notes or context (e.g. after morning walk, rested 5 mins)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Action Button
                  AppButton(
                    label: 'Save ${activeMetric['title']}',
                    backgroundColor: activeColor,
                    onPressed: () => _save(patient, settings),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
