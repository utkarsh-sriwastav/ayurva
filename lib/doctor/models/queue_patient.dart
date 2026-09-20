enum ConsultationStatus { waiting, inConsultation, checked }

/// One patient in today's queue, as the doctor sees them.
class QueuePatient {
  final int tokenNumber;
  final String patientName;
  final int age;
  final String gender;
  final ConsultationStatus status;
  final DateTime issuedAt;
  final DateTime? checkedAt;

  const QueuePatient({
    required this.tokenNumber,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.status,
    required this.issuedAt,
    this.checkedAt,
  });

  String get statusLabel {
    switch (status) {
      case ConsultationStatus.waiting:
        return 'Waiting';
      case ConsultationStatus.inConsultation:
        return 'In consultation';
      case ConsultationStatus.checked:
        return 'Checked';
    }
  }

  /// Tokens are valid only for the day they were issued.
  bool get isExpired {
    final now = DateTime.now();
    return issuedAt.year != now.year ||
        issuedAt.month != now.month ||
        issuedAt.day != now.day;
  }

  QueuePatient copyWith({ConsultationStatus? status, DateTime? checkedAt}) =>
      QueuePatient(
        tokenNumber: tokenNumber,
        patientName: patientName,
        age: age,
        gender: gender,
        status: status ?? this.status,
        issuedAt: issuedAt,
        checkedAt: checkedAt ?? this.checkedAt,
      );

  factory QueuePatient.fromJson(Map<String, dynamic> json) => QueuePatient(
        tokenNumber: json['token_number'] as int,
        patientName: json['patient_name'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        status: ConsultationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ConsultationStatus.waiting,
        ),
        issuedAt: DateTime.parse(json['issued_at'] as String),
        checkedAt: json['checked_at'] == null
            ? null
            : DateTime.parse(json['checked_at'] as String),
      );
}
