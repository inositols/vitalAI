import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
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
  bool _isSharingEnabled = true;
  bool _shareVitals = true;
  bool _shareInsights = true;
  bool _notifyOnCritical = true;

  final _emailController = TextEditingController();
  final List<CaregiverModel> _activeCaregivers = [
    CaregiverModel(
      id: '1',
      name: 'Sarah Vance (Care Coordinator)',
      email: 'sarah.vance@clinic.org',
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
      context.showSnackBar('Caregiver invitation link sent successfully');
    } else {
      context.showSnackBar('Please enter a valid email address');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, patientState) {
        if (patientState is! PatientLoadSuccess || patientState.activePatient == null) {
          return const Scaffold(
            body: AppEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No Active Patient Profile',
              message: 'Select a patient profile to manage remote caregiver permissions.',
            ),
          );
        }

        final patient = patientState.activePatient!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Caregiver Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  'Patient: ${patient.name}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              CaregiverSharingToggle(
                isSharingEnabled: _isSharingEnabled,
                onChanged: (val) => setState(() => _isSharingEnabled = val),
              ),
              const SizedBox(height: 20),
              if (_isSharingEnabled) ...[
                const AppSectionHeader(
                  title: 'Sharing Permissions',
                  subtitle: 'Control what remote caregivers are allowed to inspect',
                ),
                const SizedBox(height: 10),
                CaregiverPermissionsCard(
                  shareVitals: _shareVitals,
                  shareInsights: _shareInsights,
                  notifyOnCritical: _notifyOnCritical,
                  onShareVitalsChanged: (val) => setState(() => _shareVitals = val),
                  onShareInsightsChanged: (val) => setState(() => _shareInsights = val),
                  onNotifyOnCriticalChanged: (val) => setState(() => _notifyOnCritical = val),
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Connected Caregivers',
                  subtitle: 'Active family members and medical proxies',
                ),
                const SizedBox(height: 10),
                CaregiverListCard(
                  caregivers: _activeCaregivers,
                  onDelete: (cg) => setState(() => _activeCaregivers.remove(cg)),
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Invite Trusted Caregiver',
                  subtitle: 'Grant remote clinical access via email invite',
                ),
                const SizedBox(height: 10),
                InviteCaregiverCard(
                  controller: _emailController,
                  onSendInvite: _addCaregiver,
                ),
                const SizedBox(height: 16),
              ] else
                AppCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.shield_outlined, size: 44, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Remote Sharing Disabled',
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enable remote data sharing above to add caregivers, invite medical proxies, or manage automated emergency alerts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
