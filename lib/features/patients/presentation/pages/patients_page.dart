import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient Profile?'),
        content: Text(
          'Are you sure you want to delete "${patient.name}"? All logged vitals associated with this profile will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PatientBloc>().add(
                    PatientDeleted(localId: patient.id, remoteId: patient.remoteId),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
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
                  hintText: 'Search profiles...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Who is tracking today?'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search Profiles',
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientLoadSuccess) {
            final filteredPatients = state.patients.where((p) {
              return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredPatients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    const Text('No patient profiles found.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add First Patient'),
                      onPressed: () => _openPatientForm(),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredPatients.length,
              itemBuilder: (ctx, index) {
                final patient = filteredPatients[index];
                final isActive = state.activePatient?.id == patient.id;

                return PatientCardTile(
                  patient: patient,
                  isActive: isActive,
                  onSelect: () {
                    context
                        .read<PatientBloc>()
                        .add(PatientSelected(patient));
                    context.go('/');
                  },
                  onEdit: () => _openPatientForm(patient),
                  onDelete: () => _confirmDelete(patient),
                );
              },
            );
          }

          return const Center(child: Text('Failed to load patient profiles.'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
        onPressed: () => _openPatientForm(),
      ),
    );
  }
}
