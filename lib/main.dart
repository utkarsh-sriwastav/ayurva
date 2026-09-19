import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'common/routes/app_routes.dart';
import 'common/screens/welcome_screen.dart';
import 'common/screens/patient_login_screen.dart';
import 'common/screens/doctor_login_screen.dart';
import 'common/screens/otp_verification_screen.dart';
import 'common/utils/navigator_key.dart';
import 'patient/patient_home_screen.dart';
import 'doctor/doctor_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Requires google-services.json (Android) / GoogleService-Info.plist
  // (iOS) to already be added to the project — see FIREBASE_SETUP.md.
  // If you instead run `flutterfire configure`, it will generate a
  // lib/firebase_options.dart file; in that case switch this line to
  // `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
  // and import that generated file above.
  await Firebase.initializeApp();

  runApp(const AyurvaApp());
}

class AyurvaApp extends StatelessWidget {
  const AyurvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayurva',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D5B)),
        scaffoldBackgroundColor: const Color(0xFFF6FAF8),
      ),
      initialRoute: AppRoutes.welcome,
      routes: {
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.patientLogin: (context) => const PatientLoginScreen(),
        AppRoutes.doctorLogin: (context) => const DoctorLoginScreen(),
        AppRoutes.otpVerification: (context) => const OtpVerificationScreen(),
        AppRoutes.patientHome: (context) => const PatientHomeScreen(),
        AppRoutes.doctorHome: (context) => const DoctorHomeScreen(),
      },
    );
  }
}
