import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../reminders/presentation/bloc/reminders_bloc.dart';
import '../../../reminders/presentation/bloc/reminders_event.dart';
import '../../../reminders/presentation/bloc/reminders_state.dart';
import '../../../reminders/data/models/reminder_model.dart';
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
  // Hydration state
  int _waterIntakeMl = 0;
  int _waterGoalMl = 2000;
  Map<DateTime, int> _weeklyWaterHistory = {};

  // Steps state
  int _stepsCount = 8420;
  int _stepsGoal = 10000;

  // Sleep state
  double _sleepHours = 7.33; // 7h 20m
  String _sleepQuality = 'Optimal';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLocalHealthData();
    locator<NotificationService>().requestPermissions();
  }

  String _getDateKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}_${now.month}_${now.day}';
  }

  int _getActivePatientId() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      return patientState.activePatient!.id;
    }
    return 0;
  }

  Future<void> _loadLocalHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pid = _getActivePatientId();
      final dateKey = _getDateKey();

      final savedWater = prefs.getInt('hydration_intake_${pid}_$dateKey');
      final savedWaterGoal = prefs.getInt('hydration_goal_$pid');
      final savedSteps = prefs.getInt('steps_${pid}_$dateKey');
      final savedStepsGoal = prefs.getInt('steps_goal_$pid');
      final savedSleepHours = prefs.getDouble('sleep_hours_${pid}_$dateKey');
      final savedSleepQuality = prefs.getString('sleep_quality_${pid}_$dateKey');

      // Load 7-day hydration history for the weekly trend
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final Map<DateTime, int> weeklyMap = {};
      for (int i = 6; i >= 0; i--) {
        final day = todayMidnight.subtract(Duration(days: i));
        final dayKey = _getDateKey(day);
        final intake = prefs.getInt('hydration_intake_${pid}_$dayKey') ?? 0;
        weeklyMap[day] = intake;
      }

      if (mounted) {
        setState(() {
          _waterIntakeMl = savedWater ?? 0;
          _waterGoalMl = savedWaterGoal ?? 2000;
          _weeklyWaterHistory = weeklyMap;
          if (savedSteps != null) _stepsCount = savedSteps;
          if (savedStepsGoal != null) _stepsGoal = savedStepsGoal;
          if (savedSleepHours != null) _sleepHours = savedSleepHours;
          if (savedSleepQuality != null) _sleepQuality = savedSleepQuality;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveWaterIntake(int amount) async {
    final pid = _getActivePatientId();
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final dateKey = _getDateKey(now);
    final clamped = amount.clamp(0, 10000);
    setState(() {
      _waterIntakeMl = clamped;
      _weeklyWaterHistory = Map<DateTime, int>.from(_weeklyWaterHistory)..[todayMidnight] = clamped;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hydration_intake_${pid}_$dateKey', _waterIntakeMl);
      await prefs.setInt('hydration_goal_$pid', _waterGoalMl);
    } catch (_) {}
  }

  Future<void> _saveWaterGoal(int goal) async {
    final pid = _getActivePatientId();
    final clamped = goal.clamp(500, 10000);
    setState(() {
      _waterGoalMl = clamped;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hydration_goal_$pid', _waterGoalMl);
    } catch (_) {}
  }

  void _showQuickFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$message (${_formatNumber(_waterIntakeMl)} / ${_formatNumber(_waterGoalMl)} ml)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0052CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveSteps(int count) async {
    final pid = _getActivePatientId();
    final dateKey = _getDateKey();
    setState(() {
      _stepsCount = count.clamp(0, 100000);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('steps_${pid}_$dateKey', _stepsCount);
    } catch (_) {}
  }

  Future<void> _saveSleep(double hours, String quality) async {
    final pid = _getActivePatientId();
    final dateKey = _getDateKey();
    setState(() {
      _sleepHours = hours;
      _sleepQuality = quality;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sleep_hours_${pid}_$dateKey', _sleepHours);
      await prefs.setString('sleep_quality_${pid}_$dateKey', _sleepQuality);
    } catch (_) {}
  }

  void _loadData() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      final pid = patientState.activePatient!.id;
      context.read<VitalsBloc>().add(VitalsListRequested(pid));
      context.read<RemindersBloc>().add(RemindersListRequested(pid));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
          _loadLocalHealthData();
        }
      },
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, patientState) {
          final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;
          final patientName = (activePatient != null && activePatient.name.trim().isNotEmpty)
              ? activePatient.name.trim()
              : 'User';

          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            appBar: AppTopBar(
              title: 'Dashboard',
              initials: patientName,
              onAvatarTap: () => context.go('/settings'),
              onLeadingTap: () => context.push('/add-vital'),
              leadingTooltip: 'Log Vitals',
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/add-vital'),
              backgroundColor: const Color(0xFF0062E0),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Log Vitals',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadData();
                  await _loadLocalHealthData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Greeting
                      Text(
                        '${_getGreeting()}, $patientName',
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

                      // 2. Featured Daily Goal Hero Card (Hydration Tracker)
                      _buildDailyGoalCard(context),
                      const SizedBox(height: 16),

                      // 3. Quick Action Buttons Row
                      _buildQuickActionsRow(context),
                      const SizedBox(height: 16),

                      // 4. Metric 2-Column Grid (Steps & Heart Rate)
                      BlocBuilder<VitalsBloc, VitalsState>(
                        builder: (context, vitalsState) {
                          String pulse = '72';
                          String pulseSubtitle = 'Resting avg: 68';
                          if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
                            for (var v in vitalsState.records) {
                              if (v.pulseRate != null) {
                                pulse = '${v.pulseRate!.toInt()}';
                                if (v.pulseRate! < 60) {
                                  pulseSubtitle = 'Athletic / Low resting';
                                } else if (v.pulseRate! > 100) {
                                  pulseSubtitle = 'Elevated';
                                } else {
                                  pulseSubtitle = 'Optimal resting range';
                                }
                                break;
                              }
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
                                  value: _formatNumber(_stepsCount),
                                  unit: '',
                                  subtitle: _stepsCount >= _stepsGoal
                                      ? '🎉 Goal reached!'
                                      : '${((_stepsCount / _stepsGoal) * 100).toInt()}% of $_stepsGoal goal',
                                  subtitleColor: const Color(0xFF16A34A),
                                  onTap: () => _showStepsSheet(context),
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
                                  subtitle: pulseSubtitle,
                                  subtitleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  onTap: () => context.go('/charts'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // 5. Sleep Card with Wave Graphic
                      _buildSleepCard(context),
                      const SizedBox(height: 14),

                      // 6. Favorites / Vitals Grid (Blood Pressure, Blood Glucose, SpO2)
                      BlocBuilder<VitalsBloc, VitalsState>(
                        builder: (context, vitalsState) {
                          return _buildVitalsSummarySection(context, vitalsState);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 7. Dynamic AI Insight Card
                      BlocBuilder<VitalsBloc, VitalsState>(
                        builder: (context, vitalsState) {
                          return _buildAiInsightCard(context, vitalsState);
                        },
                      ),
                      const SizedBox(height: 22),

                      // 8. Upcoming Consultation & Reminders Section
                      _buildUpcomingSection(context),
                      const SizedBox(height: 60), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // --- 1. Quick Actions Row ---
  Widget _buildQuickActionsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      {
        'icon': Icons.add_chart_rounded,
        'label': 'Log Vital',
        'color': const Color(0xFF0062E0),
        'bg': const Color(0xFFEBF5FF),
        'onTap': () => context.push('/add-vital'),
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'AI Coach',
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
        'onTap': () => context.go('/ai-chat'),
      },
      {
        'icon': Icons.show_chart_rounded,
        'label': 'Analytics',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF3E8FF),
        'onTap': () => context.go('/charts'),
      },
      {
        'icon': Icons.alarm_rounded,
        'label': 'Reminders',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFD1FAE5),
        'onTap': () => context.go('/reminders'),
      },
    ];

    return Row(
      children: actions.map((act) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: act['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? (act['color'] as Color).withValues(alpha: 0.2) : act['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        act['icon'] as IconData,
                        color: act['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 2. Daily Goal (Hydration) Hero Card ---
  Widget _buildDailyGoalCard(BuildContext context) {
    final remainingMl = (_waterGoalMl - _waterIntakeMl).clamp(0, _waterGoalMl);
    final isGoalReached = _waterIntakeMl >= _waterGoalMl;

    return InkWell(
      onTap: () => _showHydrationSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
        child: Column(
          children: [
            Row(
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
                            'DAILY HYDRATION GOAL',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isGoalReached)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Goal Met! 🎉',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isGoalReached
                            ? 'Goal Completed! 🎉'
                            : (_waterIntakeMl == 0 ? 'Start Daily Hydration' : 'Stay Hydrated'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGoalReached
                            ? 'Great job! Reached your ${_formatNumber(_waterGoalMl)} ml target.'
                            : '${_formatNumber(_waterIntakeMl)} / ${_formatNumber(_waterGoalMl)} ml ($remainingMl ml left)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Circular Progress Ring with smooth animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: (_waterIntakeMl / _waterGoalMl).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, animVal, child) {
                    final displayPct = (animVal * 100).toInt();
                    return SizedBox(
                      width: 68,
                      height: 68,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 68,
                            height: 68,
                            child: CircularProgressIndicator(
                              value: animVal,
                              strokeWidth: 6.5,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '$displayPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick Add Action Buttons directly on Hero Card
            Row(
              children: [
                Expanded(
                  child: _buildHeroQuickAddButton(
                    context,
                    label: '+250 ml',
                    icon: Icons.local_drink_rounded,
                    onTap: () {
                      _saveWaterIntake(_waterIntakeMl + 250);
                      _showQuickFeedback('💧 Added 250 ml glass of water');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHeroQuickAddButton(
                    context,
                    label: '+500 ml',
                    icon: Icons.sports_bar_rounded,
                    onTap: () {
                      _saveWaterIntake(_waterIntakeMl + 500);
                      _showQuickFeedback('💧 Added 500 ml bottle of water');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showHydrationSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'More',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
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

  Widget _buildHeroQuickAddButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Hydration Modal Sheet ---
  void _showHydrationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final pct = ((_waterIntakeMl / _waterGoalMl) * 100).clamp(0, 100).toInt();
            final remainingMl = (_waterGoalMl - _waterIntakeMl).clamp(0, _waterGoalMl);
            final isGoalReached = _waterIntakeMl >= _waterGoalMl;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBF5FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0062E0), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Hydration Tracker',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isGoalReached
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFEBF5FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isGoalReached
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF0062E0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_formatNumber(_waterIntakeMl)} / ${_formatNumber(_waterGoalMl)} ml',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGoalReached
                            ? '🎉 Great job! You reached today\'s goal!'
                            : '$remainingMl ml remaining to reach your goal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isGoalReached ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_waterIntakeMl / _waterGoalMl).clamp(0.0, 1.0),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isGoalReached ? const Color(0xFF16A34A) : const Color(0xFF0062E0),
                        ),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 22),

                      // Quick Add Buttons
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Quick Add',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickWaterButton(
                              label: '+100 ml',
                              sublabel: 'Sip',
                              icon: Icons.opacity_rounded,
                              onTap: () {
                                _saveWaterIntake(_waterIntakeMl + 100);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickWaterButton(
                              label: '+250 ml',
                              sublabel: 'Glass',
                              icon: Icons.local_drink_rounded,
                              onTap: () {
                                _saveWaterIntake(_waterIntakeMl + 250);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickWaterButton(
                              label: '+500 ml',
                              sublabel: 'Bottle',
                              icon: Icons.sports_bar_rounded,
                              onTap: () {
                                _saveWaterIntake(_waterIntakeMl + 500);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickWaterButton(
                              label: '+750 ml',
                              sublabel: 'Flask',
                              icon: Icons.fitness_center_rounded,
                              onTap: () {
                                _saveWaterIntake(_waterIntakeMl + 750);
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Target Daily Goal selector
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Target Daily Goal',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [1500, 2000, 2500, 3000].map((goal) {
                          final isSelected = _waterGoalMl == goal;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  _saveWaterGoal(goal);
                                  setSheetState(() {});
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0062E0)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0062E0)
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_formatNumber(goal)} ml',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Weekly 7-Day History Streak
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Last 7 Days',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildWeeklyHydrationBar(isDark),
                      const SizedBox(height: 18),

                      // Physiological Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0284C7), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Adequate hydration maintains blood volume, helps stabilize blood pressure, and reduces compensatory tachycardia.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Actions Row (Undo & Reset)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _saveWaterIntake((_waterIntakeMl - 250).clamp(0, 10000));
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.remove_circle_outline, size: 18),
                            label: const Text('Undo 250ml'),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Reset Today\'s Water?'),
                                  content: const Text('This will reset your logged water intake for today back to 0 ml.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(dCtx);
                                        _saveWaterIntake(0);
                                        setSheetState(() {});
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Reset Today', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyHydrationBar(bool isDark) {
    if (_weeklyWaterHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedKeys = _weeklyWaterHistory.keys.toList()..sort();
    const daysAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedKeys.map((day) {
          final intake = _weeklyWaterHistory[day] ?? 0;
          final pct = (intake / _waterGoalMl).clamp(0.0, 1.0);
          final metGoal = intake >= _waterGoalMl && intake > 0;
          final isToday = day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day;
          final dayName = isToday ? 'Today' : daysAbbr[day.weekday - 1];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (metGoal)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14)
              else
                Text(
                  intake > 0 ? '${(intake / 1000).toStringAsFixed(1)}L' : '0L',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 4),
              // Mini vertical bar
              Container(
                width: 18,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 18,
                  height: (pct * 44).clamp(0.0, 44.0),
                  decoration: BoxDecoration(
                    color: metGoal
                        ? const Color(0xFF16A34A)
                        : (intake > 0 ? const Color(0xFF0062E0) : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday
                      ? const Color(0xFF0062E0)
                      : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickWaterButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0062E0), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Steps Tracker Sheet ---
  void _showStepsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final pct = ((_stepsCount / _stepsGoal) * 100).clamp(0, 100).toInt();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_walk_rounded, color: Color(0xFF16A34A), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Step Tracker',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatNumber(_stepsCount),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Daily Goal: ${_formatNumber(_stepsGoal)} steps',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Log Activity',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _saveSteps(_stepsCount + 500);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+500'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF16A34A),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _saveSteps(_stepsCount + 1000);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+1,000'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF16A34A),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _saveSteps(_stepsCount + 2500);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.directions_run_rounded, size: 16),
                          label: const Text('+2,500'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF16A34A),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/charts');
                      },
                      icon: const Icon(Icons.insights_rounded, size: 18),
                      label: const Text('View Step & Activity Analytics'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 4. Metric Tile Widget ---
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  // --- 5. Sleep Card & Modal ---
  Widget _buildSleepCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = _sleepHours.toInt();
    final minutes = ((_sleepHours - hours) * 60).round();

    return InkWell(
      onTap: () => _showSleepSheet(context),
      borderRadius: BorderRadius.circular(18),
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
                      'Sleep Tracker',
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
                  '${hours}h ${minutes}m',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_sleepQuality duration • Tap to log',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.nightlight_round, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Log Sleep Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_sleepHours.toStringAsFixed(1)} Hours',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Slider(
                    value: _sleepHours,
                    min: 3.0,
                    max: 12.0,
                    divisions: 18,
                    label: '${_sleepHours.toStringAsFixed(1)}h',
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) {
                      _saveSleep(val, _sleepQuality);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sleep Quality',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['Optimal', 'Deep & Restful', 'Fair', 'Restless'].map((quality) {
                      final isSelected = _sleepQuality == quality;
                      return ChoiceChip(
                        label: Text(quality),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEEF2FF),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _saveSleep(_sleepHours, quality);
                            setSheetState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Sleep Log', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
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

  // --- 6. Vitals Summary Grid (BP, Glucose, SpO2) ---
  Widget _buildVitalsSummarySection(BuildContext context, VitalsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String bpVal = '120/80';
    String bpStatus = 'Optimal';
    Color bpColor = const Color(0xFF16A34A);

    String glucoseVal = '95';
    String glucoseStatus = 'Fasting';
    Color glucoseColor = const Color(0xFF16A34A);

    if (state is VitalsLoadSuccess && state.records.isNotEmpty) {
      for (var r in state.records) {
        if (r.systolic != null && r.diastolic != null) {
          bpVal = '${r.systolic!.toInt()}/${r.diastolic!.toInt()}';
          if (r.systolic! >= 140 || r.diastolic! >= 90) {
            bpStatus = 'High';
            bpColor = const Color(0xFFEF4444);
          } else if (r.systolic! >= 130 || r.diastolic! >= 80) {
            bpStatus = 'Elevated';
            bpColor = const Color(0xFFF59E0B);
          } else {
            bpStatus = 'Normal';
            bpColor = const Color(0xFF16A34A);
          }
          break;
        }
      }
      for (var r in state.records) {
        if (r.glucoseValue != null) {
          glucoseVal = '${r.glucoseValue!.toInt()}';
          glucoseStatus = r.glucoseMealContext ?? 'Fasting';
          if (r.glucoseValue! > 125) {
            glucoseColor = const Color(0xFFEF4444);
          } else if (r.glucoseValue! > 100) {
            glucoseColor = const Color(0xFFF59E0B);
          } else {
            glucoseColor = const Color(0xFF16A34A);
          }
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Key Health Vitals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/charts'),
              child: const Text(
                'Full Charts',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0062E0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // BP Card
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.monitor_heart_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
                title: 'Blood Pressure',
                value: bpVal,
                unit: 'mmHg',
                subtitle: bpStatus,
                subtitleColor: bpColor,
                onTap: () => context.go('/charts'),
              ),
            ),
            const SizedBox(width: 14),
            // Blood Glucose Card
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.bloodtype_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: 'Blood Glucose',
                value: glucoseVal,
                unit: 'mg/dL',
                subtitle: glucoseStatus,
                subtitleColor: glucoseColor,
                onTap: () => context.go('/charts'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 7. Dynamic AI Health Insight Card ---
  Widget _buildAiInsightCard(BuildContext context, VitalsState vitalsState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String insight = 'Your vitals are steady and resting metrics look optimal today. Tap to chat with your AI Doctor!';
    if (vitalsState is VitalsLoadSuccess && vitalsState.records.isNotEmpty) {
      final latest = vitalsState.records.first;
      if (latest.systolic != null && latest.diastolic != null) {
        if (latest.systolic! >= 130 || latest.diastolic! >= 80) {
          insight = 'Your blood pressure was slightly elevated at ${latest.systolic!.toInt()}/${latest.diastolic!.toInt()} mmHg. Remember to stay hydrated and practice relaxed breathing.';
        } else {
          insight = 'Your blood pressure is in great shape at ${latest.systolic!.toInt()}/${latest.diastolic!.toInt()} mmHg. Keep up the balanced routine and daily activity!';
        }
      } else if (latest.pulseRate != null) {
        insight = 'Resting heart rate is steady at ${latest.pulseRate!.toInt()} bpm. Recovery state is looking strong today.';
      }
    }

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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI HEALTH INSIGHT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13,
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

  // --- 8. Upcoming Reminders & Consultations Section ---
  Widget _buildUpcomingSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming & Reminders',
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
        BlocBuilder<RemindersBloc, RemindersState>(
          builder: (context, remindersState) {
            final reminders = remindersState is RemindersLoadSuccess
                ? remindersState.reminders
                : <ReminderModel>[];

            if (reminders.isEmpty) {
              // Default Consultation Card + Quick Add Reminder
              return Column(
                children: [
                  _buildConsultationTile(context),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => context.go('/reminders'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0062E0)),
                          SizedBox(width: 8),
                          Text(
                            '+ Add Medication or Health Reminder',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0062E0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                ...reminders.take(3).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildInteractiveReminderTile(context, r),
                    )),
                if (reminders.length < 3)
                  _buildConsultationTile(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInteractiveReminderTile(BuildContext context, ReminderModel reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        context.read<RemindersBloc>().add(
              ReminderCompletionToggled(
                id: reminder.id,
                patientId: reminder.patientId,
              ),
            );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: reminder.isCompleted
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
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
            // Blue/Green accent pill
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: reminder.isCompleted ? const Color(0xFF10B981) : const Color(0xFF0062E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Checkbox icon
            Icon(
              reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: reminder.isCompleted ? const Color(0xFF10B981) : const Color(0xFF0062E0),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                      color: reminder.isCompleted
                          ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.time,
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
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              onPressed: () => context.go('/reminders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go('/reminders'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                    'Dr. Jenkins • Health Checkup',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
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
    );
  }
}
