import 'package:flutter/material.dart';

import '../models/queue_patient.dart';

/// Waiting / In consultation / Checked pill used in the queue list.
class StatusChip extends StatelessWidget {
  final ConsultationStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (status) {
      case ConsultationStatus.waiting:
        color = Colors.blueGrey;
        label = 'Waiting';
        break;
      case ConsultationStatus.inConsultation:
        color = Colors.orange;
        label = 'In consultation';
        break;
      case ConsultationStatus.checked:
        color = Colors.green;
        label = '\u2713 Checked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
