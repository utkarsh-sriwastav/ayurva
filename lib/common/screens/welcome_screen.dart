import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// First screen the user sees. Lets them choose to continue as
/// a Patient or a Doctor.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 84,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ayurva',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Faster OPD check-ins.\nAI-assisted patient summaries.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.patientLogin),
                icon: const Icon(Icons.person_outline),
                label: const Text('Login as Patient'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.doctorLogin),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Login as Doctor'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Prototype build — mock login only',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
