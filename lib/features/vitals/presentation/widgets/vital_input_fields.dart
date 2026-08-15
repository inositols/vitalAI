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

  void _step(TextEditingController controller, double delta, {double? min, double? max, bool isInt = true}) {
    final cur = double.tryParse(controller.text) ?? (min ?? 0);
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

  // 1. Clean Minimal BP Input (Side-by-side with Expanded to prevent overflow)
  Widget _buildBpInput(BuildContext context) {
    final sys = double.tryParse(systolicController.text);
    final dia = double.tryParse(diastolicController.text);

    String status = 'Normal';
    Color statusColor = AppColors.secondary;

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
                color: AppColors.bpVital,
                onMinus: () => _step(systolicController, -1, min: 70, max: 240),
                onPlus: () => _step(systolicController, 1, min: 70, max: 240),
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
                color: AppColors.bpVital,
                onMinus: () => _step(diastolicController, -1, min: 40, max: 140),
                onPlus: () => _step(diastolicController, 1, min: 40, max: 140),
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
          color: AppColors.glucoseVital,
          onMinus: () => _step(glucoseController, isMmol ? -0.1 : -1, min: 20, max: 500, isInt: !isMmol),
          onPlus: () => _step(glucoseController, isMmol ? 0.1 : 1, min: 20, max: 500, isInt: !isMmol),
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
    final status = (spo2 ?? 98) >= 95 ? 'Normal (95-100%)' : 'Low Saturation';
    final statusColor = (spo2 ?? 98) >= 95 ? AppColors.secondary : AppColors.warning;

    return Column(
      children: [
        _buildStatusPill(status, statusColor),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'OXYGEN SATURATION',
          controller: spo2Controller,
          color: AppColors.spo2Vital,
          onMinus: () => _step(spo2Controller, -1, min: 70, max: 100),
          onPlus: () => _step(spo2Controller, 1, min: 70, max: 100),
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
    return Column(
      children: [
        _buildStatusPill('Resting Target (60-100 BPM)', AppColors.secondary),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'HEART RATE',
          controller: pulseController,
          color: AppColors.pulseVital,
          onMinus: () => _step(pulseController, -1, min: 35, max: 220),
          onPlus: () => _step(pulseController, 1, min: 35, max: 220),
        ),
        const SizedBox(height: 12),
        const Text(
          'BPM (Beats per minute)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 5. Clean Minimal Temperature Input
  Widget _buildTempInput(BuildContext context) {
    final isF = settings.tempUnit == 'F';

    return Column(
      children: [
        _buildStatusPill('Normal Baseline', AppColors.secondary),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'BODY TEMPERATURE',
          controller: tempController,
          color: AppColors.tempVital,
          onMinus: () => _step(tempController, isF ? -0.1 : -0.1, min: isF ? 90 : 32, max: isF ? 108 : 42, isInt: false),
          onPlus: () => _step(tempController, isF ? 0.1 : 0.1, min: isF ? 90 : 32, max: isF ? 108 : 42, isInt: false),
        ),
        const SizedBox(height: 12),
        Text(
          '°${settings.tempUnit}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // 6. Clean Minimal Weight Input
  Widget _buildWeightInput(BuildContext context) {
    final isLbs = settings.weightUnit == 'lbs';

    return Column(
      children: [
        _buildStatusPill('Weight Entry', AppColors.primary),
        const SizedBox(height: 18),
        _buildSingleNumberBox(
          label: 'BODY WEIGHT',
          controller: weightController,
          color: AppColors.weightVital,
          onMinus: () => _step(weightController, isLbs ? -0.5 : -0.2, min: 20, max: 400, isInt: false),
          onPlus: () => _step(weightController, isLbs ? 0.5 : 0.2, min: 20, max: 400, isInt: false),
        ),
        const SizedBox(height: 12),
        Text(
          settings.weightUnit,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // Compact Number Box for Dual BP inputs inside Expanded (Never overflows)
  Widget _buildCompactBox({
    required String label,
    required TextEditingController controller,
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
                constraints: const BoxConstraints(minWidth: 44, maxWidth: 64),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
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

  // Single Centered Number Box for standalone metrics
  Widget _buildSingleNumberBox({
    required String label,
    required TextEditingController controller,
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
              width: 90,
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
                decoration: const InputDecoration(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String val, String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.glucoseVital : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.glucoseVital : const Color(0xFF94A3B8).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
