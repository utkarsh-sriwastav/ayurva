/// One-page pre-consultation report for one token. There is exactly ONE
/// report per token ID, and both the Patient and the Doctor side read
/// this same report using that token ID.
class ConsultationSummary {
  final String tokenId;
  final int tokenNumber;
  final String patientName;
  final String hospital;
  final String doctor;

  /// The problem chosen at booking (e.g. "Skin Problem"), if known.
  final String? problem;
  final String specialty;

  /// What the patient typed or said, in their own words (any language).
  final List<String> patientWords;

  /// Symptoms the assistant recognised. May be empty; the patient's own
  /// words above are always the source of truth.
  final List<String> symptoms;
  final String? duration;
  final String? severity;
  final List<String> reports;
  final List<String> redFlags;

  /// The AI-written summary text.
  final String aiSummary;
  final DateTime createdAt;

  const ConsultationSummary({
    required this.tokenId,
    required this.tokenNumber,
    required this.patientName,
    required this.hospital,
    required this.doctor,
    required this.problem,
    required this.specialty,
    required this.patientWords,
    required this.symptoms,
    required this.duration,
    required this.severity,
    required this.reports,
    required this.redFlags,
    required this.aiSummary,
    required this.createdAt,
  });
}