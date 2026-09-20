import '../models/attendance_record.dart';
import '../models/attendance_summary.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_stats.dart';
import '../models/patient_history.dart';
import '../models/presence_event.dart';
import '../models/queue_patient.dart';
import 'doctor_repository.dart';

/// In-memory stand-in for the backend so the doctor module can be built and
/// demoed before the API exists. State lives for the life of the app session.
///
/// Deleting this file and pointing `DoctorRepository.instance` at the real
/// API implementation must be the only change needed.
class MockDoctorRepository implements DoctorRepository {
  static const _delay = Duration(milliseconds: 500);

  // --- state --------------------------------------------------------------

  DoctorProfile _profile = const DoctorProfile(
    id: 'DOC001',
    name: 'Meera Nair',
    department: 'General Medicine',
    phone: '9876500001',
    isPresent: false,
  );

  final List<PresenceEvent> _presenceEvents = [];
  final Map<String, AttendanceRecord> _attendance = {};
  final List<QueuePatient> _queue = [];

  int _totalConsultations = 1248;
  bool _seeded = false;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // --- seed data ----------------------------------------------------------

  void _seed() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();
    final today = _dayOf(now);

    // Past attendance for this month: present on weekdays, two days off.
    for (var day = 1; day < today.day; day++) {
      final date = DateTime(today.year, today.month, day);
      if (date.weekday == DateTime.sunday) continue;

      final absentDay = day % 7 == 3; // a couple of absences for realism
      if (absentDay) {
        _attendance[_key(date)] = AttendanceRecord(
          date: date,
          presentAt: null,
          absentAt: null,
          duration: Duration.zero,
          status: AttendanceStatus.absent,
        );
      } else {
        final inAt = DateTime(date.year, date.month, date.day, 9, 10);
        final outAt = DateTime(date.year, date.month, date.day, 16, 40);
        _attendance[_key(date)] = AttendanceRecord(
          date: date,
          presentAt: inAt,
          absentAt: outAt,
          duration: outAt.difference(inAt),
          status: AttendanceStatus.present,
        );
      }
    }

    // Today's queue.
    const seed = [
      [7, 'Ramesh Kumar', 46, 'Male'],
      [8, 'Sunita Devi', 31, 'Female'],
      [9, 'Abdul Hafeez', 58, 'Male'],
      [10, 'Priya Sharma', 24, 'Female'],
      [11, 'Vikas Yadav', 37, 'Male'],
      [12, 'Anjali Gupta', 29, 'Female'],
    ];
    final issuedAt = DateTime(today.year, today.month, today.day, 9);
    for (final row in seed) {
      _queue.add(QueuePatient(
        tokenNumber: row[0] as int,
        patientName: row[1] as String,
        age: row[2] as int,
        gender: row[3] as String,
        status: ConsultationStatus.waiting,
        issuedAt: issuedAt,
      ));
    }
  }

  // --- profile & presence -------------------------------------------------

  @override
  Future<DoctorProfile> getProfile(String phone) async {
    await Future.delayed(_delay);
    _seed();
    return _profile;
  }

  @override
  Future<DoctorProfile> setPresence({
    required String doctorId,
    required bool present,
  }) async {
    await Future.delayed(_delay);
    _seed();

    final now = DateTime.now();
    _profile = _profile.copyWith(isPresent: present, statusChangedAt: now);
    _presenceEvents.add(PresenceEvent(at: now, present: present));

    final today = _dayOf(now);
    final existing = _attendance[_key(today)];

    if (present) {
      _attendance[_key(today)] = (existing ??
              AttendanceRecord(
                date: today,
                presentAt: now,
                absentAt: null,
                duration: Duration.zero,
                status: AttendanceStatus.onDuty,
              ))
          .copyWith(
        presentAt: existing?.presentAt ?? now,
        status: AttendanceStatus.onDuty,
      );
    } else if (existing != null && existing.presentAt != null) {
      // Accumulate this stint onto whatever was already recorded today.
      final stintStart = _lastPresentStart(today) ?? existing.presentAt!;
      _attendance[_key(today)] = existing.copyWith(
        absentAt: now,
        duration: existing.duration + now.difference(stintStart),
        status: AttendanceStatus.present,
      );
    }
    return _profile;
  }

  DateTime? _lastPresentStart(DateTime day) {
    for (final e in _presenceEvents.reversed) {
      if (!e.present) continue;
      if (_dayOf(e.at) == day) return e.at;
    }
    return null;
  }

  @override
  Future<List<PresenceEvent>> getTodayPresenceEvents(String doctorId) async {
    await Future.delayed(_delay);
    final today = _dayOf(DateTime.now());
    return _presenceEvents.where((e) => _dayOf(e.at) == today).toList();
  }

  // --- attendance ---------------------------------------------------------

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String doctorId,
    required int month,
    required int year,
  }) async {
    await Future.delayed(_delay);
    _seed();

    final records = _attendance.values
        .where((r) => r.date.month == month && r.date.year == year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary({
    required String doctorId,
    required int month,
    required int year,
  }) async {
    await Future.delayed(_delay);
    _seed();
    return _summary(month, year);
  }

  AttendanceSummary _summary(int month, int year) {
    final records = _attendance.values
        .where((r) => r.date.month == month && r.date.year == year)
        .toList();

    final present = records
        .where((r) => r.status != AttendanceStatus.absent)
        .length;
    final absent = records
        .where((r) => r.status == AttendanceStatus.absent)
        .length;

    // Working days elapsed so far this month, Sundays excluded.
    final now = DateTime.now();
    final lastDay = (month == now.month && year == now.year)
        ? now.day
        : DateTime(year, month + 1, 0).day;
    var working = 0;
    for (var d = 1; d <= lastDay; d++) {
      if (DateTime(year, month, d).weekday != DateTime.sunday) working++;
    }

    var total = Duration.zero;
    for (final r in records) {
      total += r.duration;
    }

    return AttendanceSummary(
      month: month,
      year: year,
      daysPresent: present,
      daysAbsent: absent,
      workingDays: working,
      totalDuration: total,
    );
  }

  // --- dashboard ----------------------------------------------------------

  @override
  Future<DoctorStats> getStats(String doctorId) async {
    await Future.delayed(_delay);
    _seed();

    final checked = _queue
        .where((p) => p.status == ConsultationStatus.checked)
        .length;
    final waiting = _queue
        .where((p) => p.status == ConsultationStatus.waiting)
        .length;
    final inConsult = _queue
        .where((p) => p.status == ConsultationStatus.inConsultation)
        .toList();

    final now = DateTime.now();
    final summary = _summary(now.month, now.year);

    var current = 0;
    if (inConsult.isNotEmpty) {
      current = inConsult.first.tokenNumber;
    } else {
      for (final p in _queue) {
        if (p.status == ConsultationStatus.checked) current = p.tokenNumber;
      }
    }

    return DoctorStats(
      todayPatients: _queue.length,
      checkedToday: checked,
      waitingToday: waiting,
      inConsultationToday: inConsult.length,
      currentToken: current,
      totalConsultations: _totalConsultations,
      checkedThisMonth: 186 + checked,
      daysPresent: summary.daysPresent,
      workingDays: summary.workingDays,
      totalDutyDuration: summary.totalDuration,
    );
  }

  // --- queue --------------------------------------------------------------

  @override
  Future<List<QueuePatient>> getTodayQueue(String doctorId) async {
    await Future.delayed(_delay);
    _seed();
    return List.unmodifiable(_queue);
  }

  @override
  Future<QueuePatient> startConsultation(int tokenNumber) async {
    await Future.delayed(_delay);
    _seed();

    // Only one patient can be in consultation at a time.
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].status == ConsultationStatus.inConsultation) {
        _queue[i] = _queue[i].copyWith(status: ConsultationStatus.waiting);
      }
    }

    final index = _queue.indexWhere((p) => p.tokenNumber == tokenNumber);
    if (index == -1) {
      throw StateError('Token $tokenNumber is not in today\'s queue.');
    }
    _queue[index] =
        _queue[index].copyWith(status: ConsultationStatus.inConsultation);
    return _queue[index];
  }

  @override
  Future<QueuePatient> markChecked(int tokenNumber) async {
    await Future.delayed(_delay);
    _seed();

    final index = _queue.indexWhere((p) => p.tokenNumber == tokenNumber);
    if (index == -1) {
      throw StateError('Token $tokenNumber is not in today\'s queue.');
    }
    if (_queue[index].status == ConsultationStatus.checked) {
      return _queue[index];
    }

    _queue[index] = _queue[index].copyWith(
      status: ConsultationStatus.checked,
      checkedAt: DateTime.now(),
    );
    _totalConsultations += 1;
    return _queue[index];
  }

  // --- patient history & AI summary --------------------------------------

  @override
  Future<PatientHistory?> getPatientHistory(int tokenNumber) async {
    await Future.delayed(_delay);
    _seed();

    final index = _queue.indexWhere((p) => p.tokenNumber == tokenNumber);
    if (index == -1) return null;
    final patient = _queue[index];

    final detail = _details[tokenNumber] ?? _details[7]!;
    return PatientHistory(
      tokenNumber: patient.tokenNumber,
      patientName: patient.patientName,
      age: patient.age,
      gender: patient.gender,
      heightCm: detail.heightCm,
      weightKg: detail.weightKg,
      bloodGroup: detail.bloodGroup,
      allergies: detail.allergies,
      chronicConditions: detail.chronicConditions,
      visits: detail.visits,
      aiSummary: _summaries[tokenNumber],
    );
  }

  final Map<int, String> _summaries = {};

  @override
  Future<String> generateAiSummary(int tokenNumber) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _seed();

    if (_summaries.containsKey(tokenNumber)) return _summaries[tokenNumber]!;

    final index = _queue.indexWhere((p) => p.tokenNumber == tokenNumber);
    if (index == -1) {
      throw StateError('Token $tokenNumber is not in today\'s queue.');
    }
    final patient = _queue[index];
    final detail = _details[tokenNumber] ?? _details[7]!;

    final summary = '''
AI-GENERATED SUMMARY FOR DOCTOR REVIEW
Token #${patient.tokenNumber} | ${patient.patientName}, ${patient.age} / ${patient.gender}

PRESENTING COMPLAINT
${detail.complaint}

HISTORY REPORTED BY PATIENT
${detail.reportedHistory}

RELEVANT BACKGROUND
Chronic: ${detail.chronicConditions.isEmpty ? 'None reported' : detail.chronicConditions.join(', ')}
Allergies: ${detail.allergies.isEmpty ? 'None reported' : detail.allergies.join(', ')}
Last visit: ${detail.visits.isEmpty ? 'First visit' : '${detail.visits.first.diagnosis} (${detail.visits.first.date.day}/${detail.visits.first.date.month}/${detail.visits.first.date.year})'}

POINTS TO CONFIRM
${detail.pointsToConfirm}

NOTE
Generated from the patient's intake conversation. This is an intake note,
not a diagnosis, and is for doctor review and correction.
''';
    _summaries[tokenNumber] = summary;
    return summary;
  }

  // --- mock clinical detail ----------------------------------------------

  static final Map<int, _PatientDetail> _details = {
    7: _PatientDetail(
      heightCm: 170,
      weightKg: 74,
      bloodGroup: 'B+',
      chronicConditions: const ['Hypertension'],
      allergies: const [],
      complaint: 'Chest tightness on climbing stairs for the last 3 days.',
      reportedHistory:
          'No fever. Discomfort settles with rest. Smoker for 10 years. '
          'Taking blood pressure medication regularly.',
      pointsToConfirm:
          'Exertional pattern and smoking history - consider cardiac workup.',
      visits: [
        PastVisit(
          date: DateTime(2026, 6, 14),
          department: 'General Medicine',
          diagnosis: 'Hypertension - routine review',
          prescription: 'Amlodipine 5mg once daily',
        ),
        PastVisit(
          date: DateTime(2026, 2, 3),
          department: 'General Medicine',
          diagnosis: 'Acute bronchitis',
          prescription: 'Antibiotic course, steam inhalation',
        ),
      ],
    ),
    8: _PatientDetail(
      heightCm: 158,
      weightKg: 60,
      bloodGroup: 'O+',
      chronicConditions: const [],
      allergies: const ['Sulfa drugs'],
      complaint: 'Headache with mild fever since yesterday evening.',
      reportedHistory:
          'Worse in the evening, tired through the day, occasional dizziness '
          'on standing. No vomiting.',
      pointsToConfirm: 'Check hydration and rule out viral fever.',
      visits: [
        PastVisit(
          date: DateTime(2026, 5, 22),
          department: 'General Medicine',
          diagnosis: 'Iron deficiency anaemia',
          prescription: 'Iron and folic acid, 3 months',
        ),
      ],
    ),
    9: _PatientDetail(
      heightCm: 165,
      weightKg: 81,
      bloodGroup: 'A+',
      chronicConditions: const ['Type 2 diabetes'],
      allergies: const [],
      complaint: 'Swelling and pain in the left knee for two weeks.',
      reportedHistory:
          'Pain worse in the morning, difficulty squatting, no injury '
          'recalled. On metformin.',
      pointsToConfirm: 'Weight-bearing pain with diabetes - consider imaging.',
      visits: [
        PastVisit(
          date: DateTime(2026, 7, 9),
          department: 'General Medicine',
          diagnosis: 'Type 2 diabetes - follow up',
          prescription: 'Metformin 500mg twice daily',
        ),
      ],
    ),
    10: _PatientDetail(
      heightCm: 162,
      weightKg: 52,
      bloodGroup: 'AB+',
      chronicConditions: const [],
      allergies: const ['Dust'],
      complaint: 'Persistent dry cough for 10 days.',
      reportedHistory:
          'Mild fever in the first three days, none now. Cough worse at night.',
      pointsToConfirm: 'Night-predominant cough - consider allergic cause.',
      visits: const [],
    ),
    11: _PatientDetail(
      heightCm: 175,
      weightKg: 88,
      bloodGroup: 'B+',
      chronicConditions: const [],
      allergies: const [],
      complaint: 'Acidity and burning after meals for a month.',
      reportedHistory:
          'Irregular meal timings, self-medicating with antacids, no weight '
          'loss reported.',
      pointsToConfirm: 'Duration over a month - review diet and red flags.',
      visits: [
        PastVisit(
          date: DateTime(2026, 4, 2),
          department: 'General Medicine',
          diagnosis: 'Gastritis',
          prescription: 'Pantoprazole 40mg before breakfast',
        ),
      ],
    ),
    12: _PatientDetail(
      heightCm: 160,
      weightKg: 55,
      bloodGroup: 'O-',
      chronicConditions: const ['Asthma'],
      allergies: const ['Pollen'],
      complaint: 'Breathlessness and wheezing over the past week.',
      reportedHistory:
          'Inhaler use has increased to three times a day. Symptoms worse '
          'early morning.',
      pointsToConfirm: 'Rising inhaler use - review control and technique.',
      visits: [
        PastVisit(
          date: DateTime(2026, 8, 18),
          department: 'General Medicine',
          diagnosis: 'Asthma - routine review',
          prescription: 'Salbutamol inhaler as needed',
        ),
      ],
    ),
  };
}

/// Private bundle of mock clinical detail per token.
class _PatientDetail {
  final double heightCm;
  final double weightKg;
  final String bloodGroup;
  final List<String> chronicConditions;
  final List<String> allergies;
  final String complaint;
  final String reportedHistory;
  final String pointsToConfirm;
  final List<PastVisit> visits;

  const _PatientDetail({
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.chronicConditions,
    required this.allergies,
    required this.complaint,
    required this.reportedHistory,
    required this.pointsToConfirm,
    required this.visits,
  });
}
