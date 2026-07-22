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
        ..deviceUsed = _deviceController.text.trim();

      context.read<VitalsBloc>().add(VitalsRecordSaved(record));
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;

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
            title: const Text('Log Health Reading'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.favorite), text: 'BP & Pulse'),
                Tab(icon: Icon(Icons.water_drop), text: 'Glucose'),
                Tab(icon: Icon(Icons.air), text: 'SpO₂'),
                Tab(icon: Icon(Icons.thermostat), text: 'Temp'),
                Tab(icon: Icon(Icons.scale), text: 'Weight'),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceController,
                      decoration: const InputDecoration(
                        labelText: 'Device Used (Optional)',
                        prefixIcon: Icon(Icons.devices),
                        hintText: 'e.g. Omron Evolv, Dexcom G7',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Symptoms (Optional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText: 'e.g. Felt slightly dizzy before taking reading',
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Vital Reading'),
                      onPressed: () => _save(patient, settings),
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
