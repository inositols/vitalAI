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

class _AddVitalPageState extends State<AddVitalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

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
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
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
        ..isSynced = false
        ..updatedAt = DateTime.now();

      context.read<VitalsBloc>().add(VitalsRecordSaved(record));
      context.showSnackBar('Vital reading recorded successfully');
      context.go('/');
    }
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
              title: 'No Active Patient Profile',
              message: 'Select a patient profile before adding vital readings.',
            ),
          );
        }

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log Vital Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  'Patient: ${patient.name}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(AppIcons.bloodPressure), text: 'BP & Pulse'),
                Tab(icon: Icon(AppIcons.glucose), text: 'Glucose'),
                Tab(icon: Icon(AppIcons.spo2), text: 'SpO₂'),
                Tab(icon: Icon(AppIcons.temperature), text: 'Temp'),
                Tab(icon: Icon(AppIcons.weight), text: 'Weight'),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VitalInputFields(
                            activeTabIndex: _activeTabIndex,
                            systolicController: _systolicController,
                            diastolicController: _diastolicController,
                            glucoseController: _glucoseController,
                            pulseController: _pulseController,
                            spo2Controller: _spo2Controller,
                            tempController: _tempController,
                            weightController: _weightController,
                            glucoseMealContext: _glucoseMealContext,
                            onGlucoseMealContextChanged: (val) =>
                                setState(() => _glucoseMealContext = val),
                            settings: settings,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _deviceController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Device Used (Optional)',
                              prefixIcon: Icon(Icons.devices_other_rounded),
                              hintText: 'e.g. Omron Evolv, Dexcom G7',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Notes & Symptoms (Optional)',
                              prefixIcon: Icon(Icons.note_alt_outlined),
                              hintText: 'e.g. Took reading before morning meal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Save Vital Reading',
                      onPressed: () => _save(patient, settings),
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
