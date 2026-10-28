import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/voice_vitals_top_bar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import '../../data/models/patient_model.dart';
import 'patient_details_page.dart';

enum PatientFilter {
  all,
  recent,
  followUp,
}

/// Patients List Screen matching Screen 5 in the concept image.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PatientFilter _currentFilter = PatientFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<PatientBloc>().add(PatientListRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  String _formatLastVisit(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Last visit: ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const VoiceVitalsTopBar(),
      body: SafeArea(
        child: BlocBuilder<PatientBloc, PatientState>(
          builder: (context, state) {
            if (state is PatientLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            List<PatientModel> allPatients = [];
            if (state is PatientLoadSuccess) {
              allPatients = state.patients;
            }

            // Filter by search query
            var filtered = allPatients.where((p) {
              final query = _searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(query) ||
                  p.remoteId.toLowerCase().contains(query) ||
                  p.medicalConditions.any((c) => c.toLowerCase().contains(query));
            }).toList();

            // Filter by selected tab (All, Recent, Follow-up)
            if (_currentFilter == PatientFilter.recent) {
              filtered = filtered.take(3).toList();
            } else if (_currentFilter == PatientFilter.followUp) {
              filtered = filtered.where((p) {
                final cond = p.medicalConditions.join(' ').toLowerCase();
                return cond.contains('hypertension') || cond.contains('diabetes') || cond.contains('pregnancy');
              }).toList();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PatientBloc>().add(PatientListRequested());
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Screen Header Title & Subtitle
                  Text(
                    'Patients',
                    style: AppTypography.headlineLarge(
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your patient list',
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Compact Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.lightTextSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips: All, Recent, Follow-up
                  Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _currentFilter == PatientFilter.all,
                        onTap: () => setState(() => _currentFilter = PatientFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Recent',
                        isSelected: _currentFilter == PatientFilter.recent,
                        onTap: () => setState(() => _currentFilter = PatientFilter.recent),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Follow-up',
                        isSelected: _currentFilter == PatientFilter.followUp,
                        onTap: () => setState(() => _currentFilter = PatientFilter.followUp),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Empty State or List
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: AppEmptyState(
                        icon: Icons.person_off_rounded,
                        title: 'No Patients Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No patients match "$_searchQuery".'
                            : 'No patients in this category.',
                      ),
                    )
                  else
                    ...filtered.map((patient) {
                      return _buildPatientCard(context, patient);
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  Widget _buildPatientCard(BuildContext context, PatientModel patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = _calculateAge(patient.dateOfBirth);
    final genderInitial = patient.gender.isNotEmpty ? patient.gender[0].toUpperCase() : 'F';
    final primaryCondition = patient.medicalConditions.isNotEmpty
        ? patient.medicalConditions.first
        : 'Routine Care';

    // Extract initials
    final parts = patient.name.split(' ');
    final initials = parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'
        : (patient.name.isNotEmpty ? patient.name[0] : 'P');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Select active patient
            context.read<PatientBloc>().add(PatientSelected(patient));
            // Navigate to Patient Details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDetailsPage(patient: patient),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.subtleTealSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.subtleTealBorder),
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and Clinical Context
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: AppTypography.titleMedium(
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$genderInitial • $age yrs • $primaryCondition',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatLastVisit(patient.updatedAt),
                        style: AppTypography.labelSmall(
                          color: AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
