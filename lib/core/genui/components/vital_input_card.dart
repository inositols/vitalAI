import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../engine/genui_callbacks.dart';
import '../models/genui_component.dart';

/// Clinical vital sign input and review card with real-time physiological validation.
class VitalInputCard extends StatefulWidget {
  final GenUiComponent component;
  final GenUiInputCallback? onSaveVitals;
  final GenUiActionCallback? onActionSelected;
  final GenUiVoidCallback? onCancel;

  const VitalInputCard({
    super.key,
    required this.component,
    this.onSaveVitals,
    this.onActionSelected,
    this.onCancel,
  });

  @override
  State<VitalInputCard> createState() => _VitalInputCardState();
}

class _VitalInputCardState extends State<VitalInputCard> {
  late final TextEditingController _systolicCtrl;
  late final TextEditingController _diastolicCtrl;
  late final TextEditingController _pulseCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _spo2Ctrl;
  late final TextEditingController _respCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    final d = widget.component.data;
    _systolicCtrl = TextEditingController(text: d['systolic']?.toString() ?? d['bp_systolic']?.toString() ?? '');
    _diastolicCtrl = TextEditingController(text: d['diastolic']?.toString() ?? d['bp_diastolic']?.toString() ?? '');
    _pulseCtrl = TextEditingController(text: d['pulse']?.toString() ?? d['heartRate']?.toString() ?? '');
    _tempCtrl = TextEditingController(text: d['temperature']?.toString() ?? d['temp']?.toString() ?? '');
    _spo2Ctrl = TextEditingController(text: d['spo2']?.toString() ?? d['oxygenSaturation']?.toString() ?? '');
    _respCtrl = TextEditingController(text: d['respiratoryRate']?.toString() ?? d['rr']?.toString() ?? '');
    _weightCtrl = TextEditingController(text: d['weight']?.toString() ?? '');
    _heightCtrl = TextEditingController(text: d['height']?.toString() ?? '');
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    _respCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final sysStr = _systolicCtrl.text.trim();
    final diaStr = _diastolicCtrl.text.trim();

    if (sysStr.isNotEmpty && diaStr.isNotEmpty) {
      final sys = double.tryParse(sysStr);
      final dia = double.tryParse(diaStr);
      if (sys == null || dia == null) {
        setState(() => _validationError = 'Blood pressure readings must be valid numbers.');
        return false;
      }
      if (sys <= dia) {
        setState(() => _validationError = 'Systolic ($sys mmHg) must be greater than diastolic ($dia mmHg).');
        return false;
      }
      if (sys < 50 || sys > 300 || dia < 30 || dia > 200) {
        setState(() => _validationError = 'Blood pressure readings are outside physiological range.');
        return false;
      }
    }

    final pulseStr = _pulseCtrl.text.trim();
    if (pulseStr.isNotEmpty) {
      final pulse = double.tryParse(pulseStr);
      if (pulse != null && (pulse < 20 || pulse > 300)) {
        setState(() => _validationError = 'Pulse rate ($pulse bpm) is outside plausible range.');
        return false;
      }
    }

    final tempStr = _tempCtrl.text.trim();
    if (tempStr.isNotEmpty) {
      final temp = double.tryParse(tempStr);
      if (temp != null && (temp < 28 || temp > 45)) {
        setState(() => _validationError = 'Temperature ($temp °C) is outside plausible human range.');
        return false;
      }
    }

    setState(() => _validationError = null);
    return true;
  }

  void _submit() {
    if (!_validateInputs()) return;

    final data = <String, dynamic>{
      'patientId': widget.component.data['patientId'],
      'patientName': widget.component.data['patientName'],
      if (_systolicCtrl.text.isNotEmpty) 'systolic': double.tryParse(_systolicCtrl.text),
      if (_diastolicCtrl.text.isNotEmpty) 'diastolic': double.tryParse(_diastolicCtrl.text),
      if (_pulseCtrl.text.isNotEmpty) 'pulse': double.tryParse(_pulseCtrl.text),
      if (_tempCtrl.text.isNotEmpty) 'temperature': double.tryParse(_tempCtrl.text),
      if (_spo2Ctrl.text.isNotEmpty) 'spo2': double.tryParse(_spo2Ctrl.text),
      if (_respCtrl.text.isNotEmpty) 'respiratoryRate': double.tryParse(_respCtrl.text),
      if (_weightCtrl.text.isNotEmpty) 'weight': double.tryParse(_weightCtrl.text),
      if (_heightCtrl.text.isNotEmpty) 'height': double.tryParse(_heightCtrl.text),
      'recordedAt': DateTime.now().toIso8601String(),
    };

    widget.onSaveVitals?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.component.data['patientName']?.toString();
    final title = widget.component.title ??
        (patientName != null ? 'Record Vitals for $patientName' : 'Record Patient Vitals');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.lightBorder),
          // BP Row (Systolic / Diastolic)
          Row(
            children: [
              Expanded(
                child: _buildMetricField('Systolic BP', 'mmHg', _systolicCtrl, isRequired: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricField('Diastolic BP', 'mmHg', _diastolicCtrl, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pulse & Temp Row
          Row(
            children: [
              Expanded(
                child: _buildMetricField('Pulse / HR', 'bpm', _pulseCtrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricField('Temperature', '°C', _tempCtrl),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // SpO2 & Resp Rate Row
          Row(
            children: [
              Expanded(
                child: _buildMetricField('Oxygen (SpO2)', '%', _spo2Ctrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricField('Resp. Rate', 'breaths/min', _respCtrl),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weight & Height Row
          Row(
            children: [
              Expanded(
                child: _buildMetricField('Weight', 'kg', _weightCtrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricField('Height', 'cm', _heightCtrl),
              ),
            ],
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Review & Save Vitals'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricField(
    String label,
    String unit,
    TextEditingController controller, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
            suffixText: unit,
            suffixStyle: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

