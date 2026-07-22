import 'package:flutter/material.dart';
import 'package:vitalai/features/settings/presentation/bloc/settings_state.dart';

class VitalInputFields extends StatelessWidget {
  final int activeTabIndex;
  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController glucoseController;
  final TextEditingController pulseController;
  final TextEditingController spo2Controller;
  final TextEditingController tempController;
  final TextEditingController weightController;
  final String glucoseMealContext;
  final ValueChanged<String> onGlucoseMealContextChanged;
  final SettingsState settings;

  const VitalInputFields({
    super.key,
    required this.activeTabIndex,
    required this.systolicController,
    required this.diastolicController,
    required this.glucoseController,
    required this.pulseController,
    required this.spo2Controller,
    required this.tempController,
    required this.weightController,
    required this.glucoseMealContext,
    required this.onGlucoseMealContextChanged,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeTabIndex) {
      case 0:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: systolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Systolic (mmHg)',
                      prefixIcon: Icon(Icons.favorite, color: Colors.redAccent),
                      hintText: 'e.g. 120',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: diastolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic (mmHg)',
                      prefixIcon: Icon(Icons.favorite_border, color: Colors.redAccent),
                      hintText: 'e.g. 80',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heart Rate / Pulse (BPM)',
                prefixIcon: Icon(Icons.monitor_heart, color: Colors.purpleAccent),
                hintText: 'e.g. 72',
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            TextFormField(
              controller: glucoseController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Glucose Level (${settings.glucoseUnit})',
                prefixIcon: const Icon(Icons.water_drop, color: Colors.orangeAccent),
                hintText: settings.glucoseUnit == 'mg/dL' ? 'e.g. 95' : 'e.g. 5.3',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: glucoseMealContext,
              decoration: const InputDecoration(
                labelText: 'Meal Context',
                prefixIcon: Icon(Icons.restaurant),
              ),
              items: const [
                DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                DropdownMenuItem(value: 'before_meal', child: Text('Before Meal')),
                DropdownMenuItem(value: 'after_meal', child: Text('After Meal')),
                DropdownMenuItem(value: 'random', child: Text('Random')),
              ],
              onChanged: (val) {
                if (val != null) onGlucoseMealContextChanged(val);
              },
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            TextFormField(
              controller: spo2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Oxygen Saturation SpO₂ (%)',
                prefixIcon: Icon(Icons.air, color: Colors.cyan),
                hintText: 'e.g. 98',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pulse (BPM)',
                prefixIcon: Icon(Icons.monitor_heart, color: Colors.purpleAccent),
                hintText: 'e.g. 72',
              ),
            ),
          ],
        );
      case 3:
        return TextFormField(
          controller: tempController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Body Temperature (°${settings.tempUnit})',
            prefixIcon: const Icon(Icons.thermostat, color: Colors.deepOrange),
            hintText: settings.tempUnit == 'C' ? 'e.g. 36.6' : 'e.g. 97.8',
          ),
        );
      case 4:
        return TextFormField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Body Weight (${settings.weightUnit})',
            prefixIcon: const Icon(Icons.scale, color: Colors.green),
            hintText: settings.weightUnit == 'kg' ? 'e.g. 70.5' : 'e.g. 155.0',
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
