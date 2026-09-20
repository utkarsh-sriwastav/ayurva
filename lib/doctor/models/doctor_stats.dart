/// Every number shown on the doctor dashboard, in one object so the screen
/// makes a single repository call.
class DoctorStats {
  final int todayPatients;
  final int checkedToday;
  final int waitingToday;
  final int inConsultationToday;
  final int currentToken;
  final int totalConsultations;
  final int checkedThisMonth;
  final int daysPresent;
  final int workingDays;
  final Duration totalDutyDuration;

  const DoctorStats({
    required this.todayPatients,
    required this.checkedToday,
    required this.waitingToday,
    required this.inConsultationToday,
    required this.currentToken,
    required this.totalConsultations,
    required this.checkedThisMonth,
    required this.daysPresent,
    required this.workingDays,
    required this.totalDutyDuration,
  });

  double get attendancePercentage =>
      workingDays == 0 ? 0 : (daysPresent / workingDays) * 100;

  double get averagePerDay =>
      daysPresent == 0 ? 0 : checkedThisMonth / daysPresent;

  factory DoctorStats.fromJson(Map<String, dynamic> json) => DoctorStats(
        todayPatients: json['today_patients'] as int,
        checkedToday: json['checked_today'] as int,
        waitingToday: json['waiting_today'] as int,
        inConsultationToday: json['in_consultation_today'] as int? ?? 0,
        currentToken: json['current_token'] as int,
        totalConsultations: json['total_consultations'] as int,
        checkedThisMonth: json['checked_this_month'] as int,
        daysPresent: json['days_present'] as int,
        workingDays: json['working_days'] as int,
        totalDutyDuration:
            Duration(minutes: json['total_duty_minutes'] as int? ?? 0),
      );
}
