import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/clinical_note.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../vitals/data/models/vital_record.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../activity/data/models/activity_item.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';

/// Patient Details Screen matching Screen 6 in the concept image.
class PatientDetailsPage extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailsPage({super.key, required this.patient});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClinicalNote> _notes = [];
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<VitalsBloc>().add(VitalsListRequested(widget.patient.id));
    _loadClinicalNotes();

    // Log Activity: Patient viewed
    context.read<ActivityBloc>().add(
          ActivityLogged(
            ActivityItem(
              title: 'Patient viewed',
              subtitle: widget.patient.name,
              timestamp: DateTime.now(),
              category: ActivityCategory.patients,
              patientId: widget.patient.id,
              patientName: widget.patient.name,
              statusBadge: 'Synced',
            ),
          ),
        );
  }

  Future<void> _loadClinicalNotes() async {
    try {
      final repo = locator<PatientRepository>();
      final notes = await repo.getClinicalNotes(widget.patient.id);
      if (mounted) {
        setState(() {
          _notes = notes;
          _loadingNotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age > 0 ? age : 34;
  }

  void _openDraftNoteModal() {
    final visitTypeController = TextEditingController(text: 'Follow-up Consultation');
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Draft Clinical Note',
                style: AppTypography.titleLarge(color: isDark ? Colors.white : AppColors.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient: ${widget.patient.name} (${widget.patient.remoteId})',
                style: AppTypography.bodySmall(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: visitTypeController,
                decoration: const InputDecoration(labelText: 'Visit Type / Encounter'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Clinical SOAP Findings & Plan',
                  hintText: 'Subjective complaints, objective findings, assessment and plan...',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Save Clinical Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final text = noteController.text.trim();
                    if (text.isEmpty) return;
                    final newNote = ClinicalNote(
                      patientId: widget.patient.id,
                      visitType: visitTypeController.text.trim(),
                      content: text,
                      authorName: 'Dr. Adeyemi',
                      date: DateTime.now(),
                    );
                    final repo = locator<PatientRepository>();
                    await repo.saveClinicalNote(newNote);

                    // Log activity
                    if (mounted) {
                      context.read<ActivityBloc>().add(
                            ActivityLogged(
                              ActivityItem(
                                title: 'Note added',
                                subtitle: '${newNote.visitType} • ${widget.patient.name}',
                                timestamp: DateTime.now(),
                                category: ActivityCategory.notes,
                                patientId: widget.patient.id,
                                patientName: widget.patient.name,
                              ),
                            ),
                          );
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    _loadClinicalNotes();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = _calculateAge(widget.patient.dateOfBirth);
    final genderInitial = widget.patient.gender.isNotEmpty ? widget.patient.gender[0].toUpperCase() : 'F';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.patient.name,
                  style: AppTypography.titleLarge(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSuccessContainer,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '$genderInitial • $age years • ID: ${widget.patient.remoteId}',
              style: AppTypography.labelSmall(color: AppColors.lightTextSecondary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTypography.titleSmall(color: AppColors.primary),
              unselectedLabelStyle: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Vitals'),
                Tab(text: 'History'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context),
          _buildVitalsTab(context),
          _buildHistoryTab(context),
          _buildNotesTab(context),
        ],
      ),
    );
  }

  // --- 1. OVERVIEW TAB ---
  Widget _buildOverviewTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<VitalsBloc, VitalsState>(
      builder: (context, state) {
        VitalRecord? latest;
        if (state is VitalsLoadSuccess && state.records.isNotEmpty) {
          latest = state.records.first;
        }

        final bpSys = latest?.systolic?.toInt() ?? 118;
        final bpDia = latest?.diastolic?.toInt() ?? 76;
        final hr = latest?.pulseRate?.toInt() ?? 72;
        final temp = latest?.bodyTemperature ?? 36.6;
        final spo2 = latest?.oxygenSaturation?.toInt() ?? 98;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest Vitals Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Vitals',
                    style: AppTypography.titleLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2x2 Vitals Metric Grid (BP, HR, Temp, SpO2)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'BP',
                      value: '$bpSys/$bpDia',
                      unit: 'mmHg',
                      badgeText: bpSys < 130 ? 'Normal' : 'Elevated',
                      isNormal: bpSys < 130,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'HR',
                      value: '$hr',
                      unit: 'bpm',
                      badgeText: hr <= 100 && hr >= 60 ? 'Normal' : 'Check',
                      isNormal: hr <= 100 && hr >= 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Temp',
                      value: '${temp.toStringAsFixed(1)}°C',
                      unit: '',
                      badgeText: 'Normal',
                      isNormal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'SpO₂',
                      value: '$spo2%',
                      unit: '',
                      badgeText: spo2 >= 95 ? 'Normal' : 'Low',
                      isNormal: spo2 >= 95,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Visits Section
              Text(
                'Recent Visits',
                style: AppTypography.titleLarge(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),

              // Visit 1 Card
              _buildVisitTile(
                icon: Icons.favorite_border_rounded,
                iconColor: AppColors.bpVital,
                iconBg: const Color(0xFFFEE2E2),
                date: 'Apr 22, 2025',
                title: 'General Consultation',
                summary: 'BP 118/76 • HR 72 • Temp 36.6°C',
              ),
              const SizedBox(height: 10),

              // Visit 2 Card
              _buildVisitTile(
                icon: Icons.medical_services_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                date: 'Feb 10, 2025',
                title: 'Follow-up',
                summary: 'BP 122/78 • HR 68 • Temp 36.4°C',
              ),

              const SizedBox(height: 24),

              // Quick Action: Record Vital for this patient
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_chart_rounded, color: Colors.white, size: 18),
                  label: const Text('Record Vital Signs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.push('/confirm-vital');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String badgeText,
    required bool isNormal,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isNormal ? AppColors.successContainer : AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isNormal ? AppColors.onSuccessContainer : AppColors.onWarningContainer,
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
                value,
                style: AppTypography.vitalValueMedium(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.vitalUnit(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String date,
    required String title,
    required String summary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.titleSmall(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. VITALS TAB ---
  Widget _buildVitalsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<VitalsBloc, VitalsState>(
      builder: (context, state) {
        if (state is VitalsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final records = state is VitalsLoadSuccess ? state.records : <VitalRecord>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart Title
              Text(
                'Blood Pressure Trend (Last 7 Days)',
                style: AppTypography.titleLarge(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Systolic & Diastolic tracking in mmHg',
                style: AppTypography.bodySmall(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),

              // Interactive fl_chart LineChart Container
              Container(
                height: 220,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 30,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 30,
                          reservedSize: 32,
                          getTitlesWidget: (val, meta) => Text(
                            val.toInt().toString(),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            final days = ['19', '20', '21', '22', '23', '24', '25', '26'];
                            if (idx >= 0 && idx < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[idx],
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 60,
                    maxY: 150,
                    lineBarsData: [
                      // Systolic Line (Teal)
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 128),
                          FlSpot(1, 125),
                          FlSpot(2, 126),
                          FlSpot(3, 118),
                          FlSpot(4, 122),
                          FlSpot(5, 124),
                          FlSpot(6, 120),
                          FlSpot(7, 118),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
                      ),
                      // Diastolic Line (Muted Slate)
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 84),
                          FlSpot(1, 81),
                          FlSpot(2, 82),
                          FlSpot(3, 76),
                          FlSpot(4, 79),
                          FlSpot(5, 80),
                          FlSpot(6, 78),
                          FlSpot(7, 76),
                        ],
                        isCurved: true,
                        color: const Color(0xFF94A3B8),
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recorded Readings',
                    style: AppTypography.titleLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Reading'),
                    onPressed: () => context.push('/confirm-vital'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (records.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No vitals records logged yet.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final r = records[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, color: AppColors.bpVital, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.systolic?.toInt() ?? "--"}/${r.diastolic?.toInt() ?? "--"} mmHg',
                                  style: AppTypography.titleMedium(
                                    color: isDark ? Colors.white : AppColors.secondary,
                                  ),
                                ),
                                if (r.note != null && r.note!.isNotEmpty)
                                  Text(
                                    r.note!,
                                    style: AppTypography.bodySmall(color: AppColors.lightTextSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${r.dateTime.month}/${r.dateTime.day} ${r.dateTime.hour}:${r.dateTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.labelSmall(color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. HISTORY TAB ---
  Widget _buildHistoryTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Conditions
          Text(
            'Active Medical Conditions',
            style: AppTypography.titleLarge(
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.patient.medicalConditions.isEmpty
                ? [
                    Chip(
                      label: const Text('None reported'),
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    ),
                  ]
                : widget.patient.medicalConditions.map((cond) {
                    return Chip(
                      avatar: const Icon(Icons.health_and_safety_rounded, size: 16, color: AppColors.primary),
                      label: Text(cond, style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.subtleTealSurface,
                      side: const BorderSide(color: AppColors.subtleTealBorder),
                    );
                  }).toList(),
          ),

          const SizedBox(height: 24),

          // Known Allergies
          Text(
            'Known Allergies',
            style: AppTypography.titleLarge(
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.patient.allergies.isEmpty
                ? [
                    Chip(
                      label: const Text('No known allergies (NKDA)'),
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    ),
                  ]
                : widget.patient.allergies.map((allergy) {
                    return Chip(
                      avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                      label: Text(allergy, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                      backgroundColor: AppColors.errorContainer,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    );
                  }).toList(),
          ),

          const SizedBox(height: 24),

          // Current Prescribed Medications
          Text(
            'Current Prescriptions',
            style: AppTypography.titleLarge(
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.patient.medications.isEmpty)
            const Text('No active prescriptions listed.')
          else
            ...widget.patient.medications.map((med) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        med,
                        style: AppTypography.titleSmall(color: isDark ? Colors.white : AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Emergency Contact
          if (widget.patient.emergencyContact.isNotEmpty) ...[
            Text(
              'Emergency Contact',
              style: AppTypography.titleLarge(color: isDark ? Colors.white : AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    widget.patient.emergencyContact,
                    style: AppTypography.bodyMedium(color: isDark ? Colors.white : AppColors.secondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. NOTES TAB ---
  Widget _buildNotesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingNotes) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinical Visit Notes',
                style: AppTypography.titleLarge(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Draft Note', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _openDraftNoteModal,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'No clinical notes yet.',
                      style: AppTypography.titleMedium(color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Draft Note" or say "Draft a note for my current visit" to create one.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(color: AppColors.lightTextMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._notes.map((note) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          note.visitType,
                          style: AppTypography.titleSmall(
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        Text(
                          '${note.date.month}/${note.date.day}/${note.date.year}',
                          style: AppTypography.labelSmall(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Author: ${note.authorName}',
                      style: AppTypography.labelSmall(color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.content,
                      style: AppTypography.bodyMedium(
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
