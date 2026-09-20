import '../models/attendance_record.dart';
import '../models/attendance_summary.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_stats.dart';
import '../models/patient_history.dart';
import '../models/presence_event.dart';
import '../models/queue_patient.dart';
import 'mock_doctor_repository.dart';

/// Everything the doctor module needs from the outside world.
///
/// Screens talk ONLY to [DoctorRepository.instance] - never to the mock
/// directly. When the backend is ready, add
/// `ApiDoctorRepository implements DoctorRepository`, and set
/// `DoctorRepository.instance = ApiDoctorRepository()` once at startup.
/// No screen, widget, or model has to change: every method below maps to one
/// endpoint, and the models already carry fromJson/toJson with the field
/// names from contract.md.
abstract class DoctorRepository {
  static DoctorRepository instance = MockDoctorRepository();

  // --- Profile & presence -------------------------------------------------
  // GET  /doctors/me
  Future<DoctorProfile> getProfile(String phone);

  /// Marks the doctor Present / Not Present and stamps the change time.
  /// Tokens are only issued to patients while the doctor is Present.
  // POST /doctors/{id}/presence
  Future<DoctorProfile> setPresence({
    required String doctorId,
    required bool present,
  });

  /// Raw presence changes for today, newest last.
  // GET /doctors/{id}/presence/events?date=today
  Future<List<PresenceEvent>> getTodayPresenceEvents(String doctorId);

  // --- Attendance ---------------------------------------------------------
  // GET /doctors/{id}/attendance?month=&year=
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String doctorId,
    required int month,
    required int year,
  });

  // GET /doctors/{id}/attendance/summary?month=&year=
  Future<AttendanceSummary> getAttendanceSummary({
    required String doctorId,
    required int month,
    required int year,
  });

  // --- Dashboard ----------------------------------------------------------
  // GET /doctors/{id}/stats
  Future<DoctorStats> getStats(String doctorId);

  // --- Today's queue ------------------------------------------------------
  // GET /doctors/{id}/queue?date=today
  Future<List<QueuePatient>> getTodayQueue(String doctorId);

  /// Moves a waiting patient into In Consultation (and returns any previous
  /// in-consultation patient to the queue order).
  // POST /tokens/{token}/start
  Future<QueuePatient> startConsultation(int tokenNumber);

  /// Marks the consultation complete. Advances the current token and the
  /// checked counters.
  // POST /tokens/{token}/check
  Future<QueuePatient> markChecked(int tokenNumber);

  // --- Patient history & AI summary --------------------------------------
  /// Returns null when the token number does not exist for today.
  // GET /tokens/{token}/history
  Future<PatientHistory?> getPatientHistory(int tokenNumber);

  /// Produces the AI summary for doctor review. Mocked for now; later this
  /// hits the LLM endpoint and the screen stays untouched.
  // POST /tokens/{token}/summary
  Future<String> generateAiSummary(int tokenNumber);
}
