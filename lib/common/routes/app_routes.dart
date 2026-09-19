/// Central place for route names, so nobody hardcodes route strings
/// in their own screens. Patient/Doctor module owners: if you add
/// new screens inside your own module, feel free to add more
/// constants here (or keep your own internal routes local to your
/// module — your choice), but do not rename the ones below without
/// telling the team, since main.dart wires directly to these.
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String patientLogin = '/patient-login';
  static const String doctorLogin = '/doctor-login';
  static const String otpVerification = '/otp-verification';
  static const String patientHome = '/patient-home';
  static const String doctorHome = '/doctor-home';
}
