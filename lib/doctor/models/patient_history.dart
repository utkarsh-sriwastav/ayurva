/// One past consultation of a patient.
class PastVisit {
  final DateTime date;
  final String department;
  final String diagnosis;
  final String prescription;

  const PastVisit({
    required this.date,
    required this.department,
    required this.diagnosis,
    required this.prescription,
  });

  factory PastVisit.fromJson(Map<String, dynamic> json) => PastVisit(
        date: DateTime.parse(json['date'] as String),
        department: json['department'] as String,
        diagnosis: json['diagnosis'] as String,
        prescription: json['prescription'] as String,
      );
}

/// Everything the doctor sees after entering a token number: the patient's
/// details, their vitals, past visits, and the AI-generated intake summary.
class PatientHistory {
  final int tokenNumber;
  final String patientName;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<PastVisit> visits;

  /// Null until the doctor asks for the summary to be generated.
  final String? aiSummary;

  const PatientHistory({
    required this.tokenNumber,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.visits,
    this.aiSummary,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  PatientHistory copyWith({String? aiSummary}) => PatientHistory(
        tokenNumber: tokenNumber,
        patientName: patientName,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        bloodGroup: bloodGroup,
        allergies: allergies,
        chronicConditions: chronicConditions,
        visits: visits,
        aiSummary: aiSummary ?? this.aiSummary,
      );

  factory PatientHistory.fromJson(Map<String, dynamic> json) => PatientHistory(
        tokenNumber: json['token_number'] as int,
        patientName: json['patient_name'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        heightCm: (json['height_cm'] as num).toDouble(),
        weightKg: (json['weight_kg'] as num).toDouble(),
        bloodGroup: json['blood_group'] as String? ?? 'Unknown',
        allergies: (json['allergies'] as List?)?.cast<String>() ?? const [],
        chronicConditions:
            (json['chronic_conditions'] as List?)?.cast<String>() ?? const [],
        visits: (json['visits'] as List?)
                ?.map((v) => PastVisit.fromJson(v as Map<String, dynamic>))
                .toList() ??
            const [],
        aiSummary: json['ai_summary'] as String?,
      );
}
