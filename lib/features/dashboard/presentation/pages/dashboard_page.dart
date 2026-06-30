import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../../core/plugin/module_registry.dart';

/// Screen coordinating patient overview, trend summaries, and quick action shortcuts.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, state) {
        if (state is PatientLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PatientLoadSuccess && state.activePatient != null) {
          final patient = state.activePatient!;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${patient.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active Patient Profile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.people_outline, size: 28),
                  tooltip: 'Switch Profiles',
                  onPressed: () => context.go('/patients'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Premium AI Insights Banner Card
                  _buildAiInsightsCard(context),
                  const SizedBox(height: 24),

                  // 2. Quick Add Actions Grid
                  Text(
                    'Quick Log Vitals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickAddGrid(context),
                  const SizedBox(height: 24),

                  // 3. Dynamic Plugin Cards Registry Section
                  Text(
                    'Trends & Health Metrics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ModuleRegistry.instance.modules.map((module) {
                    final cards = module.buildDashboardCards(context, patient.id.toString());
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: cards.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: c,
                          )).toList(),
                    );
                  }),
                  
                  // Default helper card if no modules loaded
                  if (ModuleRegistry.instance.modules.isEmpty)
                    Card(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Initialize vitals plugins to show logs.",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Return profile selector if no active patient profile selected
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_box_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Select Profile Context',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Please choose a patient context to view health logs.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/patients'),
                    child: const Text('Go to Selection Screen'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiInsightsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/ai-chat'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'AI Insights',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"Your average resting heart rate has improved by 6% over the last week. Elevated blood pressure checks indicate resting after high readings is helping."',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ask AI Assistant',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddGrid(BuildContext context) {
    final actions = [
      _QuickAddBtn(
        icon: Icons.bloodtype_outlined,
        label: 'BP',
        color: Colors.red,
        onTap: () => context.push('/vitals/add'),
      ),
      _QuickAddBtn(
        icon: Icons.opacity_outlined,
        label: 'Glucose',
        color: Colors.orange,
        onTap: () => context.push('/vitals/add'),
      ),
      _QuickAddBtn(
        icon: Icons.heart_broken_outlined,
        label: 'Pulse',
        color: Colors.pink,
        onTap: () => context.push('/vitals/add'),
      ),
      _QuickAddBtn(
        icon: Icons.thermostat_outlined,
        label: 'Temp',
        color: Colors.blue,
        onTap: () => context.push('/vitals/add'),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: actions,
    );
  }
}

class _QuickAddBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
