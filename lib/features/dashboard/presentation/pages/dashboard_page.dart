import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../vitals/presentation/bloc/vitals_bloc.dart';
import '../../../vitals/presentation/bloc/vitals_event.dart';
import '../../../vitals/presentation/bloc/vitals_state.dart';
import '../../../../core/plugin/module_registry.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/notifications/notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadVitals();
    locator<NotificationService>().requestPermissions();
  }

  void _loadVitals() {
    final patientState = context.read<PatientBloc>().state;
    if (patientState is PatientLoadSuccess &&
        patientState.activePatient != null) {
      context.read<VitalsBloc>().add(
        VitalsListRequested(patientState.activePatient!.id),
      );
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
    final theme = Theme.of(context);

    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientLoadSuccess && state.activePatient != null) {
          context.read<VitalsBloc>().add(
            VitalsListRequested(state.activePatient!.id),
          );
        }
      },
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientLoadSuccess && state.activePatient != null) {
            final patient = state.activePatient!;

            return Scaffold(
              appBar: AppBar(
                // leading: IconButton(
                //   icon: const Icon(Icons.arrow_back),
                //   tooltip: 'Back to Profiles',
                //   onPressed: () => context.go('/patients'),
                // ),
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, ${patient.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Active Patient Profile',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  BlocBuilder<VitalsBloc, VitalsState>(
                    builder: (context, vitalsState) {
                      final isSyncing = vitalsState is VitalsLoading;
                      return IconButton(
                        icon: isSyncing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_outlined, size: 28),
                        tooltip: 'Sync Vitals Data',
                        onPressed: isSyncing
                            ? null
                            : () {
                                context.read<VitalsBloc>().add(
                                  VitalsSyncRequested(patient.id),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Synchronizing local database with cloud storage...',
                                    ),
                                    duration: Duration(milliseconds: 1500),
                                  ),
                                );
                              },
                      );
                    },
                  ),
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
                    // 1. Premium AI Insights Banner Card with Shimmer
                    ShimmeringInsightsCard(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.go('/ai-chat'),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'AI Insights',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Ask AI Assistant',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                      final cards = module.buildDashboardCards(
                        context,
                        patient.id.toString(),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: cards
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: c,
                              ),
                            )
                            .toList(),
                      );
                    }),

                    // Default helper card if no modules loaded
                    if (ModuleRegistry.instance.modules.isEmpty)
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
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
                    const Icon(
                      Icons.account_box_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Profile Context',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please choose a patient context to view health logs.',
                    ),
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

    return SpringTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
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
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Glowing Shimmer effect wrapper for AI Insights banner
class ShimmeringInsightsCard extends StatefulWidget {
  final Widget child;
  const ShimmeringInsightsCard({super.key, required this.child});

  @override
  State<ShimmeringInsightsCard> createState() => _ShimmeringInsightsCardState();
}

class _ShimmeringInsightsCardState extends State<ShimmeringInsightsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double value = _controller.value;
        // Shift light gradient left to right
        final Alignment start = Alignment(-3.0 + (value * 6.0), -1.0);
        final Alignment end = Alignment(-1.5 + (value * 6.0), 1.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.transparent,
                        ],
                        begin: start,
                        end: end,
                        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

// Spring tap scaling feedback helper
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SpringTap({super.key, required this.child, this.onTap});

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) {
        if (widget.onTap != null) {
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () => widget.onTap != null ? _controller.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
