/// Temporary mock OTP authentication for the Ayurva prototype.
///
/// Real Firebase Phone Authentication is kept separately and can be
/// restored later when SMS billing is enabled.
///
/// Test OTP: 123456

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  /// Mock "Send OTP".
  ///
  /// No real SMS is sent.
  /// Returns a fake verification ID so the existing OTP screen
  /// and navigation flow continue to work unchanged.
  Future<PhoneOtpSendResult> sendOtp({
    required String phoneNumber,
    required void Function(dynamic credential) onAutoVerified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return PhoneOtpSendResult(
      success: true,
      verificationId: 'mock-verification-id',
      resendToken: null,
    );
  }

  /// Mock OTP verification.
  ///
  /// The prototype accepts only 123456.
  Future<PhoneOtpVerifyResult> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (verificationId != 'mock-verification-id') {
      return PhoneOtpVerifyResult(
        success: false,
        errorMessage: 'Invalid verification session.',
      );
    }

    if (smsCode.trim() == '123456') {
      return PhoneOtpVerifyResult(
        success: true,
      );
    }

    return PhoneOtpVerifyResult(
      success: false,
      errorMessage: 'Incorrect OTP. Use 123456 for this prototype.',
    );
  }

  Future<void> signOut() async {
    // Nothing to do in mock mode.
  }
}

/// Result of a mock "send OTP" attempt.
class PhoneOtpSendResult {
  final bool success;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;

  PhoneOtpSendResult({
    required this.success,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
  });
}

/// Result of OTP verification.
class PhoneOtpVerifyResult {
  final bool success;
  final dynamic userCredential;
  final String? errorMessage;

  PhoneOtpVerifyResult({
    required this.success,
    this.userCredential,
    this.errorMessage,
  });
}