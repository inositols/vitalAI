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

  final _systolicController = TextEditingController(text: '120');
  final _diastolicController = TextEditingController(text: '80');
  final _glucoseController = TextEditingController(text: '95');
  final _pulseController = TextEditingController(text: '72');
  final _spo2Controller = TextEditingController(text: '98');
  final _tempController = TextEditingController(text: '98.6');
  final _weightController = TextEditingController(text: '70.0');
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
    context.showSnackBar('✓ Vital reading recorded');
    context.go('/');
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
              onPressed: () => context.go('/'),
            ),
            title: const Text('Log Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // 1. Sleek Compact Metric Selector Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_metrics.length, (idx) {
                        final metric = _metrics[idx];
                        final isSelected = _activeMetricIndex == idx;
                        final Color color = metric['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            onTap: () => setState(() => _activeMetricIndex = idx),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              child: Text(
                                metric['short'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Focused Big Input Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    borderRadius: AppRadius.xxl,
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

                  // 3. Simple Optional Note
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add an optional note or symptom...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 28),

                  // 4. Save Button
                  AppButton(
                    label: 'Save ${activeMetric['short']} Reading',
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
