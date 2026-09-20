/// Monthly attendance statistics shown above the history list.
class AttendanceSummary {
  final int month;
  final int year;
  final int daysPresent;
  final int daysAbsent;
  final int workingDays;
  final Duration totalDuration;

  const AttendanceSummary({
    required this.month,
    required this.year,
    required this.daysPresent,
    required this.daysAbsent,
    required this.workingDays,
    required this.totalDuration,
  });

  double get attendancePercentage =>
      workingDays == 0 ? 0 : (daysPresent / workingDays) * 100;

  Duration get averageDuration => daysPresent == 0
      ? Duration.zero
      : Duration(minutes: totalDuration.inMinutes ~/ daysPresent);

  String get monthLabel => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        month: json['month'] as int,
        year: json['year'] as int,
        daysPresent: json['days_present'] as int,
        daysAbsent: json['days_absent'] as int,
        workingDays: json['working_days'] as int,
        totalDuration: Duration(minutes: json['total_minutes'] as int? ?? 0),
      );
}
