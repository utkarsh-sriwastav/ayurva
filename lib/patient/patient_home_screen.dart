import 'package:flutter/material.dart';

import 'data/patient_repository.dart';
import 'models/token.dart';
import 'screens/ai_consultant_screen.dart';
import 'screens/patient_details_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/token_booking_screen.dart';

/// Patient home screen. Other Patient screens are opened from here.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  // Placeholder until the real patient phone number is passed in
  // after login. It is used for both booking and finding the token.
  static const String _patientPhone = '9999999999';

  static const String _noTokenMessage =
      'Book a token first to start your consultation.';

  Token? _activeToken;
  bool _hasSummary = false;

  @override
  void initState() {
    super.initState();
    _loadActiveToken();
  }

  /// Finds the active token, and whether its summary already exists.
  Future<void> _loadActiveToken() async {
    final repo = PatientRepository.instance;
    final token = await repo.getActiveToken(patientPhone: _patientPhone);
    final summary =
        token == null ? null : await repo.getConsultationSummary(token.id);
    if (!mounted) return;
    setState(() {
      _activeToken = token;
      _hasSummary = summary != null;
    });
  }

  Future<void> _openTokenBooking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TokenBookingScreen(patientPhone: _patientPhone),
      ),
    );
    // Back from booking: check if a token was booked.
    _loadActiveToken();
  }

  Future<void> _openAiConsultant(String? name) async {
    final token = _activeToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_noTokenMessage)),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiConsultantScreen(
          tokenId: token.id,
          patientName: name ?? 'Patient',
        ),
      ),
    );
    // Back from the consultation: a summary may have been created.
    _loadActiveToken();
  }

  void _openSummary(Token token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(tokenId: token.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The full name is passed in as the route argument after login.
    final name = ModalRoute.of(context)?.settings.arguments as String?;
    final token = _activeToken;

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Home')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${name ?? 'Patient'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _openTokenBooking,
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Book Token'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openAiConsultant(name),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('AI Consultant'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (token != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your active token: ${token.tokenNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    _noTokenMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
                if (token != null && _hasSummary) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openSummary(token),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('My Consultation Summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientDetailsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Complete Profile'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}