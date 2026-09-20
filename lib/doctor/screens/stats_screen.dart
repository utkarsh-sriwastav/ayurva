import 'package:flutter/material.dart';

import '../data/doctor_repository.dart';
import '../models/doctor_stats.dart';
import '../widgets/stat_card.dart';

/// Total consultation statistics - the fuller view behind the dashboard's
/// headline numbers.
class StatsScreen extends StatelessWidget {
  final String doctorId;

  const StatsScreen({super.key, required this.doctorId});

  static String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation statistics')),
      body: SafeArea(
        child: FutureBuilder<DoctorStats>(
          future: DoctorRepository.instance.getStats(doctorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Could not load: ${snapshot.error}'));
            }
            final stats = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Today',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    StatCard(
                      label: "Today's patients",
                      value: '${stats.todayPatients}',
                      icon: Icons.groups_outlined,
                    ),
                    StatCard(
                      label: 'Checked',
                      value: '${stats.checkedToday}',
                      icon: Icons.check_circle_outline,
                    ),
                    StatCard(
                      label: 'Waiting',
                      value: '${stats.waitingToday}',
                      icon: Icons.hourglass_empty,
                    ),
                    StatCard(
                      label: 'Current token',
                      value: stats.currentToken == 0
                          ? '-'
                          : '#${stats.currentToken}',
                      icon: Icons.play_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('This month',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    StatCard(
                      label: 'Patients checked',
                      value: '${stats.checkedThisMonth}',
                      icon: Icons.calendar_month_outlined,
                    ),
                    StatCard(
                      label: 'Average per day',
                      value: stats.averagePerDay.toStringAsFixed(1),
                      icon: Icons.trending_up,
                    ),
                    StatCard(
                      label: 'Days present',
                      value: '${stats.daysPresent} / ${stats.workingDays}',
                      icon: Icons.event_available_outlined,
                    ),
                    StatCard(
                      label: 'Attendance',
                      value:
                          '${stats.attendancePercentage.toStringAsFixed(0)}%',
                      icon: Icons.percent,
                    ),
                    StatCard(
                      label: 'Total duty hours',
                      value: _durationLabel(stats.totalDutyDuration),
                      icon: Icons.timelapse_outlined,
                    ),
                    StatCard(
                      label: 'Total consultations',
                      value: '${stats.totalConsultations}',
                      icon: Icons.medical_services_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Prototype note: figures come from local mock state and '
                  'update as you mark patients checked. The backend will '
                  'serve the same shapes later.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
