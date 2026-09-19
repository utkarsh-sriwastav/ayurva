import 'package:flutter/material.dart';

import '../models/otp_screen_args.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/firebase_auth_service.dart';

/// Shared OTP verification screen used by both Patient and Doctor
/// login. Verifies the SMS code against Firebase using the
/// verificationId supplied in [OtpScreenArgs]; which role it's
/// verifying for is also carried in those args.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(OtpScreenArgs args) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await FirebaseAuthService.instance.verifyOtp(
      verificationId: args.verificationId,
      smsCode: _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final destination = args.role == UserRole.patient
          ? AppRoutes.patientHome
          : AppRoutes.doctorHome;

      // Clears the login stack (welcome/login/otp) so the back
      // button doesn't return the user to the login flow.
      Navigator.pushNamedAndRemoveUntil(
        context,
        destination,
        (route) => false,
        arguments: args.fullName,
      );
    } else {
      setState(() => _errorText = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as OtpScreenArgs;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to +91 ${args.phoneNumber}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'OTP is required';
                    }
                    if (value.trim().length != 6) {
                      return 'Enter the 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : () => _handleVerify(args),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
