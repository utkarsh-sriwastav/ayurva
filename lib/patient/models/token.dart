/// Where a token is in the doctor's queue.
enum TokenStatus { waiting, called, checked }

class Token {
  final String id;
  final String doctorId;
  final String patientPhone;

  /// The patient's own token number (this can move back if the
  /// patient says they are not available).
  final int tokenNumber;

  /// The token the doctor is currently seeing.
  final int currentTokenNumber;

  final TokenStatus status;
  final DateTime estimatedTime;

  /// When the token was issued. Tokens expire after one day, so the
  /// app can use this later to hide old tokens.
  final DateTime issuedAt;

  /// True once the patient confirmed "I am available" (20 min check).
  final bool availabilityConfirmed;

  const Token({
    required this.id,
    required this.doctorId,
    required this.patientPhone,
    required this.tokenNumber,
    required this.currentTokenNumber,
    required this.status,
    required this.estimatedTime,
    required this.issuedAt,
    this.availabilityConfirmed = false,
  });

  /// How many patients are still before this token.
  int get patientsAhead {
    final ahead = tokenNumber - currentTokenNumber;
    return ahead < 0 ? 0 : ahead;
  }

  /// Returns a copy of this token with some fields changed.
  Token copyWith({
    int? tokenNumber,
    int? currentTokenNumber,
    TokenStatus? status,
    DateTime? estimatedTime,
    bool? availabilityConfirmed,
  }) {
    return Token(
      id: id,
      doctorId: doctorId,
      patientPhone: patientPhone,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      currentTokenNumber: currentTokenNumber ?? this.currentTokenNumber,
      status: status ?? this.status,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      issuedAt: issuedAt,
      availabilityConfirmed:
          availabilityConfirmed ?? this.availabilityConfirmed,
    );
  }
}