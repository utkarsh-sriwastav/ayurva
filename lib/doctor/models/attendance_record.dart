enum AttendanceStatus { present, absent, onDuty }

/// One day of attendance. [presentAt] is when the doctor first marked
/// Present that day, [absentAt] when they last marked Not Present.
/// [onDuty] means they are still marked Present right now.
class AttendanceRecord {
  final DateTime date;
  final DateTime? presentAt;
  final DateTime? absentAt;
  final Duration duration;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.date,
    required this.presentAt,
    required this.absentAt,
    required this.duration,
    required this.status,
  });

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onDuty:
        return 'On duty';
    }
  }

  /// "6h 40m" / "-" when nothing was recorded.
  String get durationLabel {
    if (duration.inMinutes <= 0) return '-';
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  AttendanceRecord copyWith({
    DateTime? presentAt,
    DateTime? absentAt,
    Duration? duration,
    AttendanceStatus? status,
  }) =>
      AttendanceRecord(
        date: date,
        presentAt: presentAt ?? this.presentAt,
        absentAt: absentAt ?? this.absentAt,
        duration: duration ?? this.duration,
        status: status ?? this.status,
      );

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: DateTime.parse(json['date'] as String),
        presentAt: json['present_at'] == null
            ? null
            : DateTime.parse(json['present_at'] as String),
        absentAt: json['absent_at'] == null
            ? null
            : DateTime.parse(json['absent_at'] as String),
        duration: Duration(minutes: json['duration_minutes'] as int? ?? 0),
        status: AttendanceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AttendanceStatus.absent,
        ),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'present_at': presentAt?.toIso8601String(),
        'absent_at': absentAt?.toIso8601String(),
        'duration_minutes': duration.inMinutes,
        'status': status.name,
      };
}
