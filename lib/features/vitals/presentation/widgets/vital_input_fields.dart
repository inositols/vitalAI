import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
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

  void _step(TextEditingController controller, double delta, {double? min, double? max, bool isInt = true, double defaultBaseline = 100}) {
    final cur = double.tryParse(controller.text) ?? defaultBaseline;
    var next = cur + delta;
    if (min != null && next < min) next = min;
    if (max != null && next > max) next = max;
    controller.text = isInt ? next.round().toString() : next.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    switch (activeTabIndex) {
      case 0:
        return _buildBpInput(context);
      case 1:
        return _buildGlucoseInput(context);
      case 2:
        return _buildSpo2Input(context);
      case 3:
        return _buildPulseInput(context);
      case 4:
        return _buildTempInput(context);
      case 5:
        return _buildWeightInput(context);
      default:
        return const SizedBox();
    }
  }

  // 1. Clean Minimal BP Input
  Widget _buildBpInput(BuildContext context) {
    final sys = double.tryParse(systolicController.text);
    final dia = double.tryParse(diastolicController.text);

    String status = 'Enter Reading';
    Color statusColor = const Color(0xFF64748B);

    if (sys != null && dia != null) {
      if (sys >= 180 || dia >= 120) {
        status = 'Crisis Alert';
        statusColor = AppColors.error;
      } else if (sys >= 140 || dia >= 90) {
        status = 'Stage 2 High';
        statusColor = AppColors.error;
      } else if (sys >= 130 || dia >= 80) {
        status = 'Stage 1 High';
        statusColor = AppColors.warning;
      } else if (sys >= 120 && dia < 80) {
        status = 'Elevated';
        statusColor = const Color(0xFFF59E0B);
      } else {
        status = 'Normal';
        statusColor = AppColors.secondary;
      }
    }

    return Column(
      children: [
        _buildStatusPill(status, statusColor),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildCompactBox(
                label: 'SYS',
                controller: systolicController,
                hint: '120',
                color: AppColors.bpVital,
                onMinus: () => _step(systolicController, -1, min: 70, max: 240, defaultBaseline: 120),
                onPlus: () => _step(systolicController, 1, min: 70, max: 240, defaultBaseline: 120),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '/',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: _buildCompactBox(
                label: 'DIA',
                controller: diastolicController,
                hint: '80',
                color: AppColors.bpVital,
                onMinus: () => _step(diastolicController, -1, min: 40, max: 140, defaultBaseline: 80),
                onPlus: () => _step(diastolicController, 1, min: 40, max: 140, defaultBaseline: 80),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'mmHg',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 2. Clean Minimal Glucose Input
  Widget _buildGlucoseInput(BuildContext context) {
    final isMmol = settings.glucoseUnit == 'mmol/L';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleChip('fasting', 'Fasting', glucoseMealContext == 'fasting', () => onGlucoseMealContextChanged('fasting')),
            const SizedBox(width: 8),
            _buildToggleChip('after_meal', 'After Meal', glucoseMealContext == 'after_meal', () => onGlucoseMealContextChanged('after_meal')),
            const SizedBox(width: 8),
            _buildToggleChip('random', 'General', glucoseMealContext == 'random', () => onGlucoseMealContextChanged('random')),
          ],
        ),
        const SizedBox(height: 20),
        _buildSingleNumberBox(
          label: 'GLUCOSE LEVEL',
          controller: glucoseController,
          hint: isMmol ? '5.3' : '95',
          color: AppColors.glucoseVital,
          onMinus: () => _step(glucoseController, isMmol ? -0.1 : -1, min: 20, max: 500, isInt: !isMmol, defaultBaseline: isMmol ? 5.3 : 95),
          onPlus: () => _step(glucoseController, isMmol ? 0.1 : 1, min: 20, max: 500, isInt: !isMmol, defaultBaseline: isMmol ? 5.3 : 95),
        ),
        const SizedBox(height: 12),
        Text(
          settings.glucoseUnit,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 3. Clean Minimal SpO2 Input
  Widget _buildSpo2Input(BuildContext context) {
    final spo2 = double.tryParse(spo2Controller.text);
    final status = spo2 == null
        ? 'Enter Reading'
        : (spo2 >= 95 ? 'Normal (95-100%)' : 'Low Saturation');
    final statusColor = spo2 == null
        ? const Color(0xFF64748B)
        : (spo2 >= 95 ? AppColors.secondary : AppColors.warning);

    return Column(
      children: [
        _buildStatusPill(status, statusColor),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'OXYGEN SATURATION',
          controller: spo2Controller,
          hint: '98',
          color: AppColors.spo2Vital,
          onMinus: () => _step(spo2Controller, -1, min: 70, max: 100, defaultBaseline: 98),
          onPlus: () => _step(spo2Controller, 1, min: 70, max: 100, defaultBaseline: 98),
        ),
        const SizedBox(height: 12),
        const Text(
          '% SpO₂',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 4. Clean Minimal Pulse Input
  Widget _buildPulseInput(BuildContext context) {
    final pulse = double.tryParse(pulseController.text);
    final status = pulse == null
        ? 'Enter Reading'
        : (pulse >= 60 && pulse <= 100 ? 'Normal Resting (60-100)' : (pulse > 100 ? 'Elevated Pulse' : 'Low Pulse'));
    final statusColor = pulse == null
        ? const Color(0xFF64748B)
        : (pulse >= 60 && pulse <= 100 ? AppColors.secondary : AppColors.warning);

    return Column(
      children: [
        _buildStatusPill(status, statusColor),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'HEART RATE',
          controller: pulseController,
          hint: '72',
          color: AppColors.pulseVital,
          onMinus: () => _step(pulseController, -1, min: 30, max: 220, defaultBaseline: 72),
          onPlus: () => _step(pulseController, 1, min: 30, max: 220, defaultBaseline: 72),
        ),
        const SizedBox(height: 12),
        const Text(
          'BPM',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 5. Clean Minimal Body Temperature Input
  Widget _buildTempInput(BuildContext context) {
    final isF = settings.tempUnit == 'F';
    final temp = double.tryParse(tempController.text);

    String status = 'Enter Reading';
    Color statusColor = const Color(0xFF64748B);

    if (temp != null) {
      final inC = isF ? (temp - 32) * 5 / 9 : temp;
      if (inC >= 38.0) {
        status = 'Fever';
        statusColor = AppColors.error;
      } else if (inC < 36.0) {
        status = 'Low Temperature';
        statusColor = AppColors.warning;
      } else {
        status = 'Normal';
        statusColor = AppColors.secondary;
      }
    }

    return Column(
      children: [
        _buildStatusPill(status, statusColor),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'BODY TEMPERATURE',
          controller: tempController,
          hint: isF ? '98.6' : '36.6',
          color: AppColors.tempVital,
          onMinus: () => _step(tempController, -0.1, min: isF ? 90 : 32, max: isF ? 110 : 43, isInt: false, defaultBaseline: isF ? 98.6 : 36.6),
          onPlus: () => _step(tempController, 0.1, min: isF ? 90 : 32, max: isF ? 110 : 43, isInt: false, defaultBaseline: isF ? 98.6 : 36.6),
        ),
        const SizedBox(height: 12),
        Text(
          '°${settings.tempUnit}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 6. Clean Minimal Body Weight Input
  Widget _buildWeightInput(BuildContext context) {
    final isLbs = settings.weightUnit == 'lbs';

    return Column(
      children: [
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'BODY WEIGHT',
          controller: weightController,
          hint: isLbs ? '154.0' : '70.0',
          color: AppColors.weightVital,
          onMinus: () => _step(weightController, -0.5, min: isLbs ? 40 : 20, max: isLbs ? 600 : 300, isInt: false, defaultBaseline: isLbs ? 154.0 : 70.0),
          onPlus: () => _step(weightController, 0.5, min: isLbs ? 40 : 20, max: isLbs ? 600 : 300, isInt: false, defaultBaseline: isLbs ? 154.0 : 70.0),
        ),
        const SizedBox(height: 12),
        Text(
          settings.weightUnit,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildToggleChip(String key, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.glucoseVital : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBox({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color color,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepper(Icons.remove_rounded, color, onMinus),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, maxWidth: 70),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            _buildStepper(Icons.add_rounded, color, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleNumberBox({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color color,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepper(Icons.remove_rounded, color, onMinus),
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            _buildStepper(Icons.add_rounded, color, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
