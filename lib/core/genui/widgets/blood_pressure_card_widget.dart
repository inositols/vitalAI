import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';
import '../../theme/design_tokens.dart';

class BloodPressureCardWidget extends StatefulWidget {
  final GenUiMetricSummaryModel model;

  const BloodPressureCardWidget({super.key, required this.model});

  @override
  State<BloodPressureCardWidget> createState() => _BloodPressureCardWidgetState();
}

class _BloodPressureCardWidgetState extends State<BloodPressureCardWidget> {
  late String _currentValue;
  bool _isLogged = false;
  bool _isReminderSet = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.model.value;
  }

  void _onQuickLog() {
    if (_isLogged) return;
    HapticFeedback.lightImpact();
    setState(() => _isLogged = true);

    GenUiActionHandler.quickSaveVital(
      context,
      metricType: 'Blood Pressure',
      rawValue: _currentValue,
      unit: widget.model.unit,
    );
  }

  void _onSetReminder() {
    if (_isReminderSet) return;
    HapticFeedback.selectionClick();
    setState(() => _isReminderSet = true);

    GenUiActionHandler.quickSaveReminder(
      context,
      title: 'BP Measurement Check',
      timeStr: '08:00 AM',
    );
  }

  void _openEditDialog() {
    final controller = TextEditingController(text: _currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Blood Pressure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adjust reading before saving to your records:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 120/80',
                suffixText: widget.model.unit.isNotEmpty ? widget.model.unit : 'mmHg',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  _currentValue = newText;
                  _isLogged = false;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(widget.model.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.bloodPressure,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.title.isNotEmpty ? widget.model.title : 'Blood Pressure Reading',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                    ),
                    if (widget.model.subtitle != null && widget.model.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.model.subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.model.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Large Metric Display with Quick Edit Trigger
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _currentValue,
                      style: AppTypography.vitalValueMedium(
                        color: isDark ? Colors.white : AppColors.darkBackground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.model.unit.isNotEmpty ? widget.model.unit : 'mmHg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _openEditDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'AHA: <120/80',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Action Bar with Persistent State
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(
                context,
                icon: _isLogged ? Icons.check_circle_rounded : Icons.save_rounded,
                label: _isLogged ? 'Logged to Records ✓' : 'Log to Records',
                color: _isLogged ? AppColors.success : AppColors.primary,
                isActive: _isLogged,
                onTap: _onQuickLog,
              ),
              _buildActionChip(
                context,
                icon: _isReminderSet ? Icons.notifications_active_rounded : Icons.alarm_add_rounded,
                label: _isReminderSet ? 'Reminder Set ✓' : 'Set Check Reminder',
                color: _isReminderSet ? AppColors.secondary : AppColors.secondary,
                isActive: _isReminderSet,
                onTap: _onSetReminder,
              ),
              _buildActionChip(
                context,
                icon: Icons.show_chart_rounded,
                label: 'View Charts',
                color: const Color(0xFF10B981),
                isActive: false,
                onTap: () => context.push('/charts'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'elevated':
      case 'high':
      case 'warning':
        return AppColors.warning;
      case 'critical':
      case 'severe':
        return AppColors.error;
      case 'optimal':
      case 'normal':
      default:
        return AppColors.success;
    }
  }
}
