import 'user_role.dart';

/// Arguments passed to the OTP verification screen so it knows who
/// to verify, which Firebase verification session to check the code
/// against, and where to send them afterward.
class OtpScreenArgs {
  final String fullName;
  final String phoneNumber; // local 10-digit number, for display
  final UserRole role;
  final String verificationId; // from FirebaseAuthService.sendOtp

  const OtpScreenArgs({
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.verificationId,
  });
}
