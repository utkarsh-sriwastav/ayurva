import 'package:flutter/material.dart';

import '../data/doctor_repository.dart';
import '../models/attendance_record.dart';
import '../models/attendance_summary.dart';
import '../widgets/stat_card.dart';

/// Attendance history + monthly statistics for the logged-in doctor.
class AttendanceScreen extends StatefulWidget {
  final String doctorId;

  const AttendanceScreen({super.key, required this.doctorId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _month;
  late int _year;

  AttendanceSummary? _summary;
  List<AttendanceRecord> _records = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final repo = DoctorRepository.instance;
    final summary = await repo.getAttendanceSummary(
      doctorId: widget.doctorId,
      month: _month,
      year: _year,
    );
    final records = await repo.getAttendanceHistory(
      doctorId: widget.doctorId,
      month: _month,
      year: _year,
    );

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _records = records;
      _isLoading = false;
    });
  }

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    setState(() {
      _month = m;
      _year = y;
    });
    _load();
  }

  static String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _timeLabel(DateTime? d) {
    if (d == null) return '-';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: SafeArea(
        child: _isLoading || summary == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            '${summary.monthLabel} ${summary.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        StatCard(
                          label: 'Attendance',
                          value:
                              '${summary.attendancePercentage.toStringAsFixed(0)}%',
                          icon: Icons.percent,
                        ),
                        StatCard(
                          label: 'Days present',
                          value:
                              '${summary.daysPresent} / ${summary.workingDays}',
                          icon: Icons.event_available_outlined,
                        ),
                        StatCard(
                          label: 'Days absent',
                          value: '${summary.daysAbsent}',
                          icon: Icons.event_busy_outlined,
                        ),
                        StatCard(
                          label: 'Avg. duty / day',
                          value: _durationLabel(summary.averageDuration),
                          icon: Icons.timelapse_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('History',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No attendance recorded for this month.',
                            style: TextStyle(color: Colors.black54)),
                      )
                    else
                      ..._records.map((r) => _AttendanceTile(
                            record: r,
                            dateLabel: _dateLabel(r.date),
                            presentLabel: _timeLabel(r.presentAt),
                            absentLabel: _timeLabel(r.absentAt),
                          )),
                    const SizedBox(height: 16),
                    const Text(
                      'Prototype note: history is local mock state. Today\'s '
                      'row updates live as you toggle Present / Not Present.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceRecord record;
  final String dateLabel;
  final String presentLabel;
  final String absentLabel;

  const _AttendanceTile({
    required this.record,
    required this.dateLabel,
    required this.presentLabel,
    required this.absentLabel,
  });

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (record.status) {
      case AttendanceStatus.present:
        color = Colors.green;
        break;
      case AttendanceStatus.onDuty:
        color = Colors.blue;
        break;
      case AttendanceStatus.absent:
        color = Colors.redAccent;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(record.statusLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Cell(label: 'Present at', value: presentLabel),
                _Cell(label: 'Absent at', value: absentLabel),
                _Cell(label: 'Duration', value: record.durationLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;

  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
