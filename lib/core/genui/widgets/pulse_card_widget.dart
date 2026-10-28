import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';
import '../../theme/design_tokens.dart';
import 'ecg_pulse_canvas_widget.dart';

/// Dynamic interactive cardiac pulse card with bespoke CustomPainter ECG waveform monitor.
class PulseCardWidget extends StatefulWidget {
  final GenUiMetricSummaryModel model;

  const PulseCardWidget({super.key, required this.model});

  @override
  State<PulseCardWidget> createState() => _PulseCardWidgetState();
}

class _PulseCardWidgetState extends State<PulseCardWidget> {
  bool _isLogged = false;

  void _onQuickLog() {
    if (_isLogged) return;
    HapticFeedback.lightImpact();
    setState(() => _isLogged = true);

    GenUiActionHandler.quickSaveVital(
      context,
      metricType: 'Pulse Rate',
      rawValue: widget.model.value,
      unit: widget.model.unit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numVal = double.tryParse(widget.model.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 72.0;

    return Semantics(
      label: 'Pulse rate card: ${widget.model.value} beats per minute with real-time electrocardiogram waveform.',
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pulseVital.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: AppShadows.subtle(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Heart Icon, Pulse Value, Rhythm Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pulseVital.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    color: AppColors.pulseVital,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.model.title.isNotEmpty ? widget.model.title : 'Cardiac Pulse Rate',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.model.value,
                            style: AppTypography.vitalValueMedium(
                              color: isDark ? Colors.white : AppColors.darkBackground,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.model.unit.isNotEmpty ? widget.model.unit : 'BPM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pulseVital.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.pulseVital.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.pulseVital),
                      SizedBox(width: 4),
                      Text(
                        'SINUS RHYTHM',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pulseVital,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Live CustomPainter ECG Waveform Display
            EcgPulseCanvasWidget(
              bpm: numVal,
              color: AppColors.pulseVital,
              height: 85,
            ),

            const SizedBox(height: 12),

            // Actions
            Wrap(
              spacing: 8,
              children: [
                InkWell(
                  onTap: _isLogged ? null : _onQuickLog,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isLogged
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.pulseVital.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isLogged
                            ? AppColors.success
                            : AppColors.pulseVital.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLogged ? Icons.check_circle_rounded : Icons.save_rounded,
                          size: 14,
                          color: _isLogged ? AppColors.success : AppColors.pulseVital,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLogged ? 'Logged to Records ✓' : 'Log Pulse Rate',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _isLogged ? AppColors.success : AppColors.pulseVital,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/charts'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'View Pulse Charts',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
