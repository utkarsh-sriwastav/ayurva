import '../models/consultation_message.dart';
import '../models/consultation_summary.dart';
import '../models/doctor_option.dart';
import '../models/patient_profile.dart';
import '../models/token.dart';
import 'mock_patient_repository.dart';

/// Everything the Patient screens need from "the server".
///
/// Screens should only use [PatientRepository.instance] and never
/// talk to the mock class directly. When the real backend is ready,
/// write an ApiPatientRepository that implements this class and
/// change the one line below. No screen code needs to change.
abstract class PatientRepository {
  /// Currently points to the mock (in-memory) data.
  static PatientRepository instance = MockPatientRepository();

  Future<PatientProfile?> getProfile(String phone);

  Future<void> saveProfile(PatientProfile profile);

  // ---- Token booking: hospital -> disease -> specialty -> doctor ----

  Future<List<Hospital>> getHospitals();

  Future<List<DiseaseOption>> getDiseases();

  /// Only doctors who belong to [hospitalId], match [specialty]
  /// and are currently available. Unavailable doctors are never returned.
  Future<List<DoctorOption>> getAvailableDoctors({
    required String hospitalId,
    required String specialty,
  });

  /// [problem] is the disease/problem chosen at booking (optional).
  Future<Token> requestToken({
    required String doctorId,
    required String patientPhone,
    String? problem,
  });

  /// The patient's current token (not checked yet, issued in the last
  /// 24 hours), or null if the patient has not booked one.
  Future<Token?> getActiveToken({required String patientPhone});

  Future<Token> getQueueStatus(String tokenId);

  Future<Token> confirmAvailability({
    required String tokenId,
    required bool available,
  });

  // ---- AI consultation (everything is keyed by the token ID) ----

  /// The saved conversation for this token (starts with the AI greeting).
  Future<List<ConsultationMessage>> getConsultationMessages(String tokenId);

  /// Sends a patient message and returns the AI reply.
  Future<String> sendConsultationMessage({
    required String tokenId,
    required String text,
  });

  /// Attaches a report to this consultation and returns the AI reply.
  /// Prototype: only the file name is stored, nothing is uploaded.
  Future<String> attachReport({
    required String tokenId,
    required String fileName,
  });

  /// Asks the AI to build the one-page report from the conversation.
  /// This does NOT save it: call [saveConsultationSummary] afterwards.
  Future<ConsultationSummary> generateConsultationSummary({
    required String tokenId,
    required String patientName,
  });

  /// Saves the report under [tokenId]. There is ONE report per token,
  /// and both the Patient and the Doctor side read this same one.
  Future<void> saveConsultationSummary(
    String tokenId,
    ConsultationSummary summary,
  );

  /// The saved report for this token, or null if none exists yet.
  Future<ConsultationSummary?> getConsultationSummary(String tokenId);

  /// Just the AI-written text of the summary.
  Future<String> getFinalSummary(String tokenId);
}