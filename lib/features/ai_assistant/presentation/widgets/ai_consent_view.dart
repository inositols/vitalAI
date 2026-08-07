import 'package:flutter/material.dart';

class AiConsentView extends StatelessWidget {
  final VoidCallback onGrantConsent;

  const AiConsentView({
    super.key,
    required this.onGrantConsent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Health Companion')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Analysis Consent',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'To explain readings, detect health trends, and provide summaries, VitalAI uses context-aware models to process your records securely. We never diagnose or prescribe medication without professional consultation.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Grant AI Consent'),
                onPressed: onGrantConsent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
