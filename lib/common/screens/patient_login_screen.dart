import 'package:flutter/material.dart';

import '../models/otp_screen_args.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/firebase_auth_service.dart';
import '../utils/navigator_key.dart';

/// Patient login — collects full name + phone number, then triggers
/// real Firebase Phone Auth and sends the user to OTP verification.
class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final localPhone = _phoneController.text.trim();
    // TODO: swap the +91 country code below if you need to support
    // numbers outside India.
    final e164Phone = '+91$localPhone';

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await FirebaseAuthService.instance.sendOtp(
      phoneNumber: e164Phone,
      onAutoVerified: (userCredential) {
        // Android SMS auto-retrieval verified the code before the
        // user typed anything — skip straight to Patient Home.
        rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.patientHome,
          (route) => false,
          arguments: name,
        );
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: OtpScreenArgs(
          fullName: name,
          phoneNumber: localPhone,
          role: UserRole.patient,
          verificationId: result.verificationId!,
        ),
      );
    } else {
      setState(() => _errorText = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Enter your details to continue.\n'
                  '(ABHA/Aadhaar login will replace this later.)',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length != 10) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
