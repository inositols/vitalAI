import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';

/// Screen allowing patient profile consent-driven sharing of vitals data with caregivers.
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
  final List<Map<String, dynamic>> _activeCaregivers = [
    {'name': 'Sarah Doe (Daughter)', 'email': 'sarah@example.com', 'active': true},
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
        _activeCaregivers.add({
          'name': email.split('@')[0],
          'email': email,
          'active': true,
        });
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
              // 1. Consent toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Remote Data Sharing'),
                        subtitle: const Text('Allow caregivers to access logs'),
                        value: _isSharingEnabled,
                        secondary: const Icon(Icons.share_outlined),
                        onChanged: (val) {
                          setState(() => _isSharingEnabled = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_isSharingEnabled) ...[
                // 2. Sharing Permissions Management
                _buildSectionTitle(theme, 'Sharing Permissions'),
                Card(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Share Vitals Logs'),
                        subtitle: const Text('Includes blood pressure, glucose, SpO2, etc.'),
                        value: _shareVitals,
                        onChanged: (val) => setState(() => _shareVitals = val ?? false),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        title: const Text('Share AI Insights Summaries'),
                        subtitle: const Text('Includes assistant summaries & alerts'),
                        value: _shareInsights,
                        onChanged: (val) => setState(() => _shareInsights = val ?? false),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        title: const Text('Critical Vitals Alert SMS/FCM'),
                        subtitle: const Text('Sends alerts immediately for emergency readings'),
                        value: _notifyOnCritical,
                        onChanged: (val) => setState(() => _notifyOnCritical = val ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Caregiver list
                _buildSectionTitle(theme, 'Connected Caregivers'),
                Card(
                  child: Column(
                    children: _activeCaregivers.map((cg) {
                      return ListTile(
                        title: Text(cg['name'] as String),
                        subtitle: Text(cg['email'] as String),
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _activeCaregivers.remove(cg);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Invite caregiver
                _buildSectionTitle(theme, 'Invite Trusted Caregiver'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Caregiver Email Address',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _addCaregiver,
                          child: const Text('Send Invitation Link'),
                        ),
                      ],
                    ),
                  ),
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
