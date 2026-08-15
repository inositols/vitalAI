import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../bloc/vitals_bloc.dart';
import '../bloc/vitals_event.dart';
import '../bloc/vitals_state.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _selectedPeriod = 'Daily'; // 'Daily', 'Weekly', 'Monthly'

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  void _loadVitals() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess && patientState.activePatient != null) {
      context.read<VitalsBloc>().add(VitalsListRequested(patientState.activePatient!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;
        final patientName = activePatient?.name ?? 'Alex';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          appBar: AppTopBar(
            title: 'Vitals',
            initials: patientName,
            onAvatarTap: () => context.go('/settings'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Subheader
                  Text(
                    'Your Vitals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Last synced 5 mins ago',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Segmented Period Control (Daily / Weekly / Monthly)
                  _buildPeriodSegmentedControl(context),
                  const SizedBox(height: 18),

                  // 3. Featured Heart Rate Chart Card
                  _buildHeartRateChartCard(context),
                  const SizedBox(height: 16),

                  // 4. Activity & Sleep 2-Column Grid
                  Row(
                    children: [
                      Expanded(child: _buildActivityCard(context)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildSleepQualityCard(context)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. Large CTA Button (+ Log Vitals)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-vital'),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.white),
                      label: const Text(
                        'Log Vitals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0062E0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: const Color(0xFF0062E0).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSegmentedControl(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periods = ['Daily', 'Weekly', 'Monthly'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF0B132B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeartRateChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<VitalsBloc, VitalsState>(
      builder: (context, state) {
        String pulse = '72';
        if (state is VitalsLoadSuccess && state.records.isNotEmpty) {
          for (var v in state.records) {
            if (v.pulseRate != null) pulse = '${v.pulseRate!.toInt()}';
          }
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Heart Rate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Normal',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    pulse,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'bpm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Smooth Area Chart with Time Axis
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HeartRateWavePainter(isDark: isDark),
                ),
              ),
              const SizedBox(height: 10),

              // Time Axis Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _axisLabel('12 AM', isDark),
                  _axisLabel('6 AM', isDark),
                  _axisLabel('12 PM', isDark),
                  _axisLabel('6 PM', isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _axisLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Activity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Circular Progress Ring Gauge
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk_rounded, color: Color(0xFF16A34A), size: 16),
                    const Text(
                      '7.5k',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'of 10k steps',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  '6h 45m',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Fair Quality',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Segmented Progress Bar (Deep / Light / REM)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: 3, child: Container(color: const Color(0xFF4F46E5))),
                  Expanded(flex: 5, child: Container(color: const Color(0xFF818CF8))),
                  Expanded(flex: 2, child: Container(color: const Color(0xFFEEF2FF))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem('Deep', const Color(0xFF4F46E5)),
              _legendItem('Light', const Color(0xFF818CF8)),
              _legendItem('REM', const Color(0xFFC7D2FE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _HeartRateWavePainter extends CustomPainter {
  final bool isDark;
  const _HeartRateWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF0062E0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0062E0).withValues(alpha: 0.25),
          const Color(0xFF0062E0).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw reference guideline
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      dashPaint,
    );

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.65,
      size.width * 0.25,
      size.height * 0.75,
      size.width * 0.35,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.45,
      size.height * 0.20,
      size.width * 0.55,
      size.height * 0.70,
      size.width * 0.65,
      size.height * 0.55,
    );
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.40,
      size.width * 0.85,
      size.height * 0.90,
      size.width,
      size.height * 0.35,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
