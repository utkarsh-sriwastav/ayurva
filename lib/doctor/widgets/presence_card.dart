import 'package:flutter/material.dart';

import '../models/doctor_profile.dart';

/// Present / Not Present control. Shows the current status prominently and
/// the date + time of the last change.
class PresenceCard extends StatelessWidget {
  final DoctorProfile profile;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  const PresenceCard({
    super.key,
    required this.profile,
    required this.isBusy,
    required this.onChanged,
  });

  static String formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}, $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final present = profile.isPresent;
    final color = present ? Colors.green : Colors.grey;
    final changedAt = profile.statusChangedAt;

    return Card(
      elevation: 0,
      color: present ? Colors.green.shade50 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: present ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    present ? 'Present in hospital' : 'Not present',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isBusy)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: present,
                    onChanged: onChanged,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              changedAt == null
                  ? 'Status not changed yet today.'
                  : '${present ? "Marked present" : "Marked not present"} '
                      'at ${formatDateTime(changedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Patients can take tokens only while you are marked present.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
