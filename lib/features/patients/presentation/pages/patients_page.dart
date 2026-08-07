import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import '../../data/models/patient_model.dart';
import '../widgets/patient_card_tile.dart';
import '../widgets/patient_form_modal.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  void _openPatientForm([PatientModel? patient]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PatientFormModal(
        patient: patient,
        onSave: (savedPatient) {
          context.read<PatientBloc>().add(PatientSaved(savedPatient));
        },
      ),
    );
  }

  void _confirmDelete(PatientModel patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Delete Profile?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${patient.name}"? All vitals logged under this patient profile will be permanently removed.',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PatientBloc>().add(
                    PatientDeleted(localId: patient.id, remoteId: patient.remoteId),
                  );
            },
            child: const Text('Delete Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search patient name...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Row(
                children: [
                  const AppBrandLogo(
                    size: 32,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Who are you monitoring today?',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search Profiles',
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: 4,
              itemBuilder: (ctx, index) => const AppShimmer.card(height: 180),
            );
          }

          if (state is PatientLoadSuccess) {
            final filteredPatients = state.patients.where((p) {
              return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredPatients.isEmpty) {
              return AppEmptyState(
                icon: Icons.person_off_rounded,
                title: 'No Patient Profiles Found',
                message: _searchQuery.isNotEmpty
                    ? 'No profiles match "$_searchQuery". Try searching a different name.'
                    : 'Create your first patient profile to begin recording real-time health vitals.',
                buttonText: 'Add Patient Profile',
                onAction: () => _openPatientForm(),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: filteredPatients.length,
              itemBuilder: (ctx, index) {
                final patient = filteredPatients[index];
                final isActive = state.activePatient?.id == patient.id;

                return PatientCardTile(
                  patient: patient,
                  isActive: isActive,
                  onSelect: () {
                    context.read<PatientBloc>().add(PatientSelected(patient));
                    context.go('/');
                  },
                  onEdit: () => _openPatientForm(patient),
                  onDelete: () => _confirmDelete(patient),
                );
              },
            );
          }

          return const AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Profiles',
            message: 'An error occurred while loading patient records. Please try again.',
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () => _openPatientForm(),
      ),
    );
  }
}
