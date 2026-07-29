import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../settings/presentation/bloc/settings_state.dart';

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

  Widget _buildUnitBadge(BuildContext context, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Center(
        widthFactor: 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

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
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Systolic',
                      prefixIcon: const Icon(Icons.favorite_rounded, color: AppColors.bpVital),
                      suffixIcon: _buildUnitBadge(context, 'mmHg', AppColors.bpVital),
                      hintText: '120',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: diastolicController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Diastolic',
                      prefixIcon: const Icon(Icons.favorite_outline_rounded, color: AppColors.bpVital),
                      suffixIcon: _buildUnitBadge(context, 'mmHg', AppColors.bpVital),
                      hintText: '80',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Heart Rate / Pulse',
                prefixIcon: const Icon(Icons.monitor_heart_rounded, color: AppColors.pulseVital),
                suffixIcon: _buildUnitBadge(context, 'BPM', AppColors.pulseVital),
                hintText: '72',
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Glucose Level',
                prefixIcon: const Icon(Icons.water_drop_rounded, color: AppColors.glucoseVital),
                suffixIcon: _buildUnitBadge(context, settings.glucoseUnit, AppColors.glucoseVital),
                hintText: settings.glucoseUnit == 'mg/dL' ? '95' : '5.3',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: glucoseMealContext,
              decoration: const InputDecoration(
                labelText: 'Meal Context',
                prefixIcon: Icon(Icons.restaurant_rounded, color: AppColors.glucoseVital),
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Oxygen Saturation SpO₂',
                prefixIcon: const Icon(Icons.air_rounded, color: AppColors.spo2Vital),
                suffixIcon: _buildUnitBadge(context, '%', AppColors.spo2Vital),
                hintText: '98',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Pulse',
                prefixIcon: const Icon(Icons.monitor_heart_rounded, color: AppColors.pulseVital),
                suffixIcon: _buildUnitBadge(context, 'BPM', AppColors.pulseVital),
                hintText: '72',
              ),
            ),
          ],
        );
      case 3:
        return TextFormField(
          controller: tempController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Body Temperature',
            prefixIcon: const Icon(Icons.device_thermostat_rounded, color: AppColors.tempVital),
            suffixIcon: _buildUnitBadge(context, '°${settings.tempUnit}', AppColors.tempVital),
            hintText: settings.tempUnit == 'C' ? '36.6' : '97.8',
          ),
        );
      case 4:
        return TextFormField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Body Weight',
            prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.weightVital),
            suffixIcon: _buildUnitBadge(context, settings.weightUnit, AppColors.weightVital),
            hintText: settings.weightUnit == 'kg' ? '70.5' : '155.0',
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
