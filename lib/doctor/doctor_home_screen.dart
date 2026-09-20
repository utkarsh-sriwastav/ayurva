import 'package:flutter/material.dart';


import 'screens/attendance_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/token_lookup_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  // Mock repository currently uses DOC001.
  // The real doctor ID can be connected later when backend
  // doctor profiles are implemented.
  static const String doctorId = 'DOC001';

  @override
  Widget build(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Text(
                'Welcome, Dr. ${name ?? 'Doctor'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your patients, queue and attendance.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 24),

              // Today's Queue
              _DashboardCard(
                icon: Icons.people_alt_outlined,
                title: "Today's Queue",
                subtitle: 'View patients waiting for consultation',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QueueScreen(
                        doctorId: doctorId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Statistics
              _DashboardCard(
                icon: Icons.bar_chart_outlined,
                title: 'Statistics',
                subtitle: 'View today and monthly consultation stats',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatsScreen(
                        doctorId: doctorId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Attendance
              _DashboardCard(
                icon: Icons.calendar_month_outlined,
                title: 'Attendance',
                subtitle: 'View your attendance and duty hours',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AttendanceScreen(
                        doctorId: doctorId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Token Lookup
              _DashboardCard(
                icon: Icons.search_outlined,
                title: 'Token Lookup',
                subtitle: 'Search patient history using token number',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TokenLookupScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Doctor tools are available from this dashboard.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}