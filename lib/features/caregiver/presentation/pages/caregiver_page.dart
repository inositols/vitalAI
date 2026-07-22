import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../data/models/caregiver_model.dart';
import '../widgets/caregiver_list_card.dart';
import '../widgets/caregiver_permissions_card.dart';
import '../widgets/caregiver_sharing_toggle.dart';
import '../widgets/invite_caregiver_card.dart';

class CaregiverPage extends StatefulWidget {
  const CaregiverPage({super.key});

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  bool _isSharingEnabled = false;
  bool _shareVitals = true;
  bool _shareInsights = false;
  bool _notifyOnCritical = true;

  final _emailController = TextEditingController();
  final List<CaregiverModel> _activeCaregivers = [
    CaregiverModel(
      id: '1',
      name: 'Sarah Doe (Daughter)',
      email: 'sarah@example.com',
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _addCaregiver() {
    final email = _emailController.text.trim();
    if (email.contains('@')) {
      setState(() {
        _activeCaregivers.add(
          CaregiverModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: email.split('@')[0],
            email: email,
          ),
        );
        _emailController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caregiver invitation sent successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: Center(child: Text("Please select a patient profile first.")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Caregiver Portal')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CaregiverSharingToggle(
                isSharingEnabled: _isSharingEnabled,
                onChanged: (val) => setState(() => _isSharingEnabled = val),
              ),
              const SizedBox(height: 16),
              if (_isSharingEnabled) ...[
                _buildSectionTitle(theme, 'Sharing Permissions'),
                CaregiverPermissionsCard(
                  shareVitals: _shareVitals,
                  shareInsights: _shareInsights,
                  notifyOnCritical: _notifyOnCritical,
                  onShareVitalsChanged: (val) => setState(() => _shareVitals = val),
                  onShareInsightsChanged: (val) => setState(() => _shareInsights = val),
                  onNotifyOnCriticalChanged: (val) => setState(() => _notifyOnCritical = val),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(theme, 'Connected Caregivers'),
                CaregiverListCard(
                  caregivers: _activeCaregivers,
                  onDelete: (cg) => setState(() => _activeCaregivers.remove(cg)),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(theme, 'Invite Trusted Caregiver'),
                InviteCaregiverCard(
                  controller: _emailController,
                  onSendInvite: _addCaregiver,
                ),
              ] else
                Card(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Remote data sharing is disabled. Enable remote sharing above to add caregivers, invite family members, or manage notifications.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
