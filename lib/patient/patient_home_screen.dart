import 'package:flutter/material.dart';

/// PLACEHOLDER — Patient module owner (Person B): replace the body
/// of this screen with the real Patient Home (token booking, AI
/// consultant chat/voice, summary view, etc).
///
/// Keep the class name `PatientHomeScreen` and this file path
/// (lib/patient/patient_home_screen.dart) unchanged, since
/// main.dart's routes point directly at this class. Everything
/// else inside lib/patient/ is yours to build out freely.
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${name ?? 'Patient'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Placeholder screen — token booking, AI consultant,\n'
                'and summary view go here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
