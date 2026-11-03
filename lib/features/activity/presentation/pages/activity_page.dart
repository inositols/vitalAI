import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/voice_vitals_top_bar.dart';
import '../../data/models/activity_item.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../bloc/activity_state.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../patients/presentation/pages/patient_details_page.dart';

/// Activity Screen matching Screen 8 in the concept image.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  ActivityCategory _selectedCategory = ActivityCategory.all;

  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(const ActivityListRequested());
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isYesterday = dt.year == now.year && dt.month == now.month && dt.day == (now.day - 1);

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $period';

    if (isToday) return 'Today, $timeStr';
    if (isYesterday) return 'Yesterday, $timeStr';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }

  IconData _getIconForActivity(String title, ActivityCategory category) {
    final lower = title.toLowerCase();
    if (lower.contains('blood pressure') || lower.contains('vital')) {
      return Icons.assignment_outlined;
    }
    if (lower.contains('note')) {
      return Icons.edit_note_rounded;
    }
    if (lower.contains('patient viewed') || lower.contains('patient')) {
      return Icons.person_outline_rounded;
    }
    if (lower.contains('chart') || lower.contains('trend')) {
      return Icons.insert_chart_outlined_rounded;
    }
    return Icons.schedule_rounded;
  }

  Color _getIconBgColor(String title, ActivityCategory category) {
    final lower = title.toLowerCase();
    if (lower.contains('blood pressure') || lower.contains('vital')) {
      return const Color(0xFFDCFCE7);
    }
    if (lower.contains('note')) {
      return const Color(0xFFE0F2FE);
    }
    if (lower.contains('patient viewed')) {
      return const Color(0xFFF1F5F9);
    }
    if (lower.contains('chart')) {
      return const Color(0xFFF3E8FF);
    }
    return const Color(0xFFE2E8F0);
  }

  Color _getIconColor(String title, ActivityCategory category) {
    final lower = title.toLowerCase();
    if (lower.contains('blood pressure') || lower.contains('vital')) {
      return const Color(0xFF16A34A);
    }
    if (lower.contains('note')) {
      return const Color(0xFF0284C7);
    }
    if (lower.contains('patient viewed')) {
      return AppColors.secondary;
    }
    if (lower.contains('chart')) {
      return const Color(0xFF8B5CF6);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const VoiceVitalsTopBar(),
      body: SafeArea(
        child: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            List<ActivityItem> items = [];
            if (state is ActivityLoadSuccess) {
              items = state.activities;
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ActivityBloc>().add(
                      ActivityListRequested(category: _selectedCategory),
                    );
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Title & Subtitle
                  Text(
                    'Activity',
                    style: AppTypography.headlineLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recent actions and records',
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips: All, Notes, Vitals, Patients
                  Row(
                    children: [
                      _buildCategoryChip('All', ActivityCategory.all),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Notes', ActivityCategory.notes),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Vitals', ActivityCategory.vitals),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Patients', ActivityCategory.patients),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (state is ActivityLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style: AppTypography.titleMedium(color: AppColors.lightTextSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Actions you take in VoiceVitals will be recorded here.',
                              style: AppTypography.bodySmall(color: AppColors.lightTextMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.map((item) {
                      return _buildActivityTile(context, item);
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, ActivityCategory category) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        context.read<ActivityBloc>().add(ActivityListRequested(category: category));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _getIconForActivity(item.title, item.category);
    final iconBg = _getIconBgColor(item.title, item.category);
    final iconColor = _getIconColor(item.title, item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // If linked to a patient, open details
            if (item.patientId != null) {
              final patientState = context.read<PatientBloc>().state;
              if (patientState is PatientLoadSuccess) {
                try {
                  final target = patientState.patients.firstWhere((p) => p.id == item.patientId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsPage(patient: target),
                    ),
                  );
                } catch (_) {}
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Activity Type Icon Circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),

                // Title, Subtitle, and Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.titleSmall(
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatActivityTime(item.timestamp),
                        style: AppTypography.labelSmall(
                          color: AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Badge or Chevron
                if (item.statusBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.statusBadge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSuccessContainer,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
