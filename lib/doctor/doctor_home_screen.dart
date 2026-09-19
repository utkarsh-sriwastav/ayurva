import 'package:flutter/material.dart';

/// PLACEHOLDER — Doctor module owner (Person C): replace the body
/// of this screen with the real Doctor Home (availability toggle,
/// today's/monthly stats, token lookup, mark-checked, etc).
///
/// Keep the class name `DoctorHomeScreen` and this file path
/// (lib/doctor/doctor_home_screen.dart) unchanged, since
/// main.dart's routes point directly at this class. Everything
/// else inside lib/doctor/ is yours to build out freely.
class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, Dr. ${name ?? 'Doctor'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Placeholder screen — availability toggle, stats,\n'
                'and token lookup go here.',
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
