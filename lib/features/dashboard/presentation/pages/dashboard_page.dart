import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../reminders/presentation/bloc/reminders_bloc.dart';
import '../../../reminders/presentation/bloc/reminders_event.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
    locator<NotificationService>().requestPermissions();
  }

  void _loadData() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      final pid = patientState.activePatient!.id;
      context.read<VitalsBloc>().add(VitalsListRequested(pid));
      context.read<RemindersBloc>().add(RemindersListRequested(pid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientLoadSuccess && state.activePatient != null) {
          final pid = state.activePatient!.id;
          context.read<VitalsBloc>().add(VitalsListRequested(pid));
          context.read<RemindersBloc>().add(RemindersListRequested(pid));
        }
      },
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, patientState) {
          final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;
          final patientName = activePatient?.name ?? 'Alex';

          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            appBar: AppTopBar(
              title: 'Dashboard',
              initials: patientName,
              onAvatarTap: () => context.go('/settings'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Greeting
                    Text(
                      'Good morning, $patientName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Here is your daily health summary.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Featured Daily Goal Hero Card (Electric Blue)
                    _buildDailyGoalCard(context),
                    const SizedBox(height: 16),

                    // 3. Metric 2-Column Grid (Steps & Heart Rate)
                    BlocBuilder<VitalsBloc, VitalsState>(
                      builder: (context, vitalsState) {
                        String pulse = '72';
                        if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
                          for (var v in vitalsState.records) {
                            if (v.pulseRate != null) pulse = '${v.pulseRate!.toInt()}';
                          }
                        }

                        return Row(
                          children: [
                            // Steps / Activity Tile
                            Expanded(
                              child: _buildMetricTile(
                                context,
                                icon: Icons.directions_walk_rounded,
                                iconBg: const Color(0xFFDCFCE7),
                                iconColor: const Color(0xFF16A34A),
                                title: 'Steps',
                                value: '8,420',
                                unit: '',
                                subtitle: '↑ 12% vs yesterday',
                                subtitleColor: const Color(0xFF16A34A),
                                onTap: () => context.go('/charts'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Heart Rate Tile
                            Expanded(
                              child: _buildMetricTile(
                                context,
                                icon: Icons.favorite_outline_rounded,
                                iconBg: const Color(0xFFFEE2E2),
                                iconColor: const Color(0xFFEF4444),
                                title: 'Heart Rate',
                                value: pulse,
                                unit: 'bpm',
                                subtitle: 'Resting avg: 68',
                                subtitleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                onTap: () => context.go('/charts'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 4. Sleep Card with Wave Graphic
                    _buildSleepCard(context),
                    const SizedBox(height: 14),

                    // 5. AI Insight Card
                    _buildAiInsightCard(context),
                    const SizedBox(height: 22),

                    // 6. Upcoming Consultation Section
                    _buildUpcomingSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066E5), Color(0xFF0052CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0062E0).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'DAILY GOAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay hydrated',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You're 20% away from your daily water intake goal.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Circular Progress Ring (80%)
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 0.80,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const Text(
                  '80%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Bar Graphic
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(16, const Color(0xFFC7D2FE)),
                const SizedBox(width: 4),
                _bar(28, const Color(0xFF818CF8)),
                const SizedBox(width: 4),
                _bar(20, const Color(0xFFC7D2FE)),
                const SizedBox(width: 4),
                _bar(38, const Color(0xFF4F46E5)),
                const SizedBox(width: 4),
                _bar(32, const Color(0xFF6366F1)),
                const SizedBox(width: 4),
                _bar(24, const Color(0xFF818CF8)),
                const SizedBox(width: 4),
                _bar(18, const Color(0xFFC7D2FE)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nightlight_round, color: Color(0xFF6366F1), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '7h 20m',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Optimal duration',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAiInsightCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go('/ai-chat'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI INSIGHT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your resting heart rate is lower than average today. Great job on the recovery! Keep up the balanced routine.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/reminders'),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0062E0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Consultation Tile with Left Blue Accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Blue accent pill
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0062E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Doctor Avatar
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEBF5FF),
                child: Icon(Icons.person_rounded, color: Color(0xFF0062E0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Jenkins',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Today, 2:00 PM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF0062E0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
