import '../models/consultation_message.dart';
import '../models/consultation_summary.dart';
import '../models/doctor_option.dart';
import '../models/patient_profile.dart';
import '../models/token.dart';
import 'mock_consultation_ai.dart';
import 'patient_repository.dart';

/// Fake, in-memory version of [PatientRepository].
/// Data lives only while the app is running.
class MockPatientRepository implements PatientRepository {
  // ---- Settings you can change while testing ----
  static const int _minutesPerPatient = 10;
  static const int _shiftBackBy = 6; // token 10 -> 16 if not available

  // ---- Fake hospitals ----
  static const List<Hospital> _hospitals = [
    Hospital(id: 'h_aiims', name: 'AIIMS Patna'),
    Hospital(id: 'h_igims', name: 'IGIMS Patna'),
    Hospital(id: 'h_pmch', name: 'PMCH Patna'),
    Hospital(id: 'h_nmch', name: 'NMCH Patna'),
    Hospital(id: 'h_paras', name: 'Paras HMRI Hospital'),
  ];

  // ---- Disease -> specialty mapping ----
  static const List<DiseaseOption> _diseases = [
    DiseaseOption(name: 'Fever', specialty: 'General Medicine'),
    DiseaseOption(name: 'Cold / Cough', specialty: 'General Medicine'),
    DiseaseOption(name: 'Diabetes', specialty: 'Endocrinology'),
    DiseaseOption(name: 'Skin Problem', specialty: 'Dermatology'),
    DiseaseOption(name: 'Eye Problem', specialty: 'Ophthalmology'),
    DiseaseOption(name: 'Tooth Pain', specialty: 'Dentistry'),
    DiseaseOption(name: 'Bone / Joint Pain', specialty: 'Orthopedics'),
    DiseaseOption(name: 'Heart Problem', specialty: 'Cardiology'),
  ];

  // ---- Fake doctors (names are made up) ----
  // Some doctors are unavailable, and some hospitals do not have every
  // specialty, so you can test the "no doctor available" message.
  static const List<DoctorOption> _doctors = [
    // AIIMS Patna
    DoctorOption(id: 'd101', name: 'Dr. Raj Kumar', hospitalId: 'h_aiims', specialty: 'Dermatology', available: true),
    DoctorOption(id: 'd102', name: 'Dr. Neha Sinha', hospitalId: 'h_aiims', specialty: 'General Medicine', available: true),
    DoctorOption(id: 'd103', name: 'Dr. Amit Verma', hospitalId: 'h_aiims', specialty: 'Cardiology', available: true),
    DoctorOption(id: 'd104', name: 'Dr. Sunita Rao', hospitalId: 'h_aiims', specialty: 'Ophthalmology', available: false),
    DoctorOption(id: 'd105', name: 'Dr. Manoj Tiwari', hospitalId: 'h_aiims', specialty: 'Orthopedics', available: true),

    // IGIMS Patna
    DoctorOption(id: 'd201', name: 'Dr. Priya Sharma', hospitalId: 'h_igims', specialty: 'Endocrinology', available: true),
    DoctorOption(id: 'd202', name: 'Dr. Sanjay Prasad', hospitalId: 'h_igims', specialty: 'Cardiology', available: false),
    DoctorOption(id: 'd203', name: 'Dr. Kavita Mishra', hospitalId: 'h_igims', specialty: 'General Medicine', available: true),
    DoctorOption(id: 'd204', name: 'Dr. Rohit Anand', hospitalId: 'h_igims', specialty: 'Dentistry', available: true),
    DoctorOption(id: 'd205', name: 'Dr. Anjali Kumari', hospitalId: 'h_igims', specialty: 'Dermatology', available: false),

    // PMCH Patna
    DoctorOption(id: 'd301', name: 'Dr. Vikash Singh', hospitalId: 'h_pmch', specialty: 'General Medicine', available: true),
    DoctorOption(id: 'd302', name: 'Dr. Rekha Devi', hospitalId: 'h_pmch', specialty: 'Ophthalmology', available: true),
    DoctorOption(id: 'd303', name: 'Dr. Arun Jha', hospitalId: 'h_pmch', specialty: 'Orthopedics', available: false),
    DoctorOption(id: 'd304', name: 'Dr. Pooja Gupta', hospitalId: 'h_pmch', specialty: 'Dentistry', available: true),

    // NMCH Patna
    DoctorOption(id: 'd401', name: 'Dr. Deepak Yadav', hospitalId: 'h_nmch', specialty: 'General Medicine', available: false),
    DoctorOption(id: 'd402', name: 'Dr. Shweta Rani', hospitalId: 'h_nmch', specialty: 'Dermatology', available: true),
    DoctorOption(id: 'd403', name: 'Dr. Ramesh Pandey', hospitalId: 'h_nmch', specialty: 'Cardiology', available: true),
    DoctorOption(id: 'd404', name: 'Dr. Nisha Kumari', hospitalId: 'h_nmch', specialty: 'Endocrinology', available: true),
    DoctorOption(id: 'd405', name: 'Dr. Ajay Mehta', hospitalId: 'h_nmch', specialty: 'Orthopedics', available: true),

    // Paras HMRI Hospital
    DoctorOption(id: 'd501', name: 'Dr. Sameer Khan', hospitalId: 'h_paras', specialty: 'Cardiology', available: true),
    DoctorOption(id: 'd502', name: 'Dr. Ritu Agarwal', hospitalId: 'h_paras', specialty: 'Endocrinology', available: false),
    DoctorOption(id: 'd503', name: 'Dr. Alok Ranjan', hospitalId: 'h_paras', specialty: 'Orthopedics', available: true),
    DoctorOption(id: 'd504', name: 'Dr. Meena Kumari', hospitalId: 'h_paras', specialty: 'General Medicine', available: true),
    DoctorOption(id: 'd505', name: 'Dr. Farhan Ali', hospitalId: 'h_paras', specialty: 'Ophthalmology', available: true),
    DoctorOption(id: 'd506', name: 'Dr. Tanvi Saxena', hospitalId: 'h_paras', specialty: 'Dermatology', available: true),
  ];

  // ---- Queue state per doctor (filled in when first needed) ----
  final Map<String, int> _lastIssuedToken = {};
  final Map<String, int> _currentlyServing = {};

  // ---- In-memory storage ----
  final Map<String, PatientProfile> _profiles = {}; // key: phone
  final Map<String, Token> _tokens = {}; // key: token id
  final Map<String, String> _tokenProblems = {}; // key: token id
  final Map<String, List<ConsultationMessage>> _chats = {}; // key: token id
  final Map<String, List<String>> _reports = {}; // key: token id
  final Map<String, ConsultationSummary> _summaries = {}; // key: token id
  int _idCounter = 1;

  // The fake AI used for consultation replies.
  final MockConsultationAi _ai = MockConsultationAi();

  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 500));

  DoctorOption _findDoctorOrThrow(String doctorId) {
    for (final doctor in _doctors) {
      if (doctor.id == doctorId) return doctor;
    }
    throw Exception('Doctor not found');
  }

  String _hospitalName(String hospitalId) {
    for (final hospital in _hospitals) {
      if (hospital.id == hospitalId) return hospital.name;
    }
    return hospitalId;
  }

  Token _getTokenOrThrow(String tokenId) {
    final token = _tokens[tokenId];
    if (token == null) {
      throw Exception('Token not found');
    }
    return token;
  }

  /// Gives each doctor a different starting queue (last token 6 to 14),
  /// so different doctors show different waiting times.
  int _startingLastToken(String doctorId) {
    final index = _doctors.indexWhere((d) => d.id == doctorId);
    return 6 + (index % 5) * 2;
  }

  DateTime _estimate(int tokenNumber, int currentToken) {
    final waitingPatients = tokenNumber - currentToken;
    final minutes = (waitingPatients < 0 ? 0 : waitingPatients) *
        _minutesPerPatient;
    return DateTime.now().add(Duration(minutes: minutes));
  }

  /// The chat for a token. A new chat starts with the AI greeting.
  List<ConsultationMessage> _chatFor(String tokenId) {
    return _chats.putIfAbsent(
      tokenId,
      () => [
        ConsultationMessage(
          sender: MessageSender.ai,
          text: MockConsultationAi.greeting,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Only what the patient typed (no AI messages, no attachments).
  List<String> _patientTexts(String tokenId) {
    return (_chats[tokenId] ?? [])
        .where((m) =>
            m.sender == MessageSender.patient && m.attachmentName == null)
        .map((m) => m.text)
        .toList();
  }

  /// Builds the report for a token from the conversation so far.
  ConsultationSummary _composeSummary(String tokenId, String patientName) {
    final token = _getTokenOrThrow(tokenId);
    final doctor = _findDoctorOrThrow(token.doctorId);
    final facts = _ai.factsFor(tokenId);
    final words = _patientTexts(tokenId);
    final reports = List<String>.from(_reports[tokenId] ?? []);

    return ConsultationSummary(
      tokenId: tokenId,
      tokenNumber: token.tokenNumber,
      patientName: patientName,
      hospital: _hospitalName(doctor.hospitalId),
      doctor: doctor.name,
      problem: _tokenProblems[tokenId],
      specialty: doctor.specialty,
      patientWords: words,
      symptoms: facts.symptoms,
      duration: facts.duration,
      severity: facts.severity,
      reports: reports,
      redFlags: facts.redFlags,
      aiSummary: _ai.buildSummaryText(
        patientName: patientName,
        tokenNumber: token.tokenNumber,
        doctor: doctor.name,
        specialty: doctor.specialty,
        facts: facts,
        patientWords: words,
        reports: reports,
      ),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PatientProfile?> getProfile(String phone) async {
    await _delay();
    return _profiles[phone];
  }

  @override
  Future<void> saveProfile(PatientProfile profile) async {
    await _delay();
    _profiles[profile.phone] = profile;
  }

  @override
  Future<List<Hospital>> getHospitals() async {
    await _delay();
    return _hospitals.toList();
  }

  @override
  Future<List<DiseaseOption>> getDiseases() async {
    await _delay();
    return _diseases.toList();
  }

  @override
  Future<List<DoctorOption>> getAvailableDoctors({
    required String hospitalId,
    required String specialty,
  }) async {
    await _delay();
    return _doctors
        .where((d) =>
            d.hospitalId == hospitalId &&
            d.specialty == specialty &&
            d.available)
        .toList();
  }

  @override
  Future<Token> requestToken({
    required String doctorId,
    required String patientPhone,
    String? problem,
  }) async {
    await _delay();

    final doctor = _findDoctorOrThrow(doctorId);
    if (!doctor.available) {
      throw Exception('Doctor is not available today');
    }

    // If this patient already has an active token with this doctor,
    // give the same one back instead of creating a duplicate.
    for (final existing in _tokens.values) {
      if (existing.doctorId == doctorId &&
          existing.patientPhone == patientPhone &&
          existing.status != TokenStatus.checked) {
        return existing;
      }
    }

    final lastIssued =
        _lastIssuedToken[doctorId] ?? _startingLastToken(doctorId);
    final tokenNumber = lastIssued + 1;
    _lastIssuedToken[doctorId] = tokenNumber;
    final current = _currentlyServing.putIfAbsent(doctorId, () => 2);

    final token = Token(
      id: 'tok_${_idCounter++}',
      doctorId: doctorId,
      patientPhone: patientPhone,
      tokenNumber: tokenNumber,
      currentTokenNumber: current,
      status: TokenStatus.waiting,
      estimatedTime: _estimate(tokenNumber, current),
      issuedAt: DateTime.now(),
    );
    _tokens[token.id] = token;
    if (problem != null) {
      _tokenProblems[token.id] = problem;
    }
    return token;
  }

  @override
  Future<Token?> getActiveToken({required String patientPhone}) async {
    await _delay();

    Token? active;
    for (final token in _tokens.values) {
      final isMine = token.patientPhone == patientPhone;
      final isOpen = token.status != TokenStatus.checked;
      // Tokens expire after one day.
      final isRecent =
          DateTime.now().difference(token.issuedAt) < const Duration(days: 1);
      if (isMine && isOpen && isRecent) {
        active = token; // the latest matching token wins
      }
    }
    return active;
  }

  /// Every call pretends the doctor moved one token forward,
  /// so the queue screen can show a moving queue during the demo.
  @override
  Future<Token> getQueueStatus(String tokenId) async {
    await _delay();
    var token = _getTokenOrThrow(tokenId);

    if (token.status == TokenStatus.waiting) {
      final newCurrent = token.currentTokenNumber + 1;
      final reached = newCurrent >= token.tokenNumber;
      token = token.copyWith(
        currentTokenNumber: reached ? token.tokenNumber : newCurrent,
        status: reached ? TokenStatus.called : TokenStatus.waiting,
        estimatedTime: _estimate(token.tokenNumber, newCurrent),
      );
      _tokens[tokenId] = token;
    }
    return token;
  }

  @override
  Future<Token> confirmAvailability({
    required String tokenId,
    required bool available,
  }) async {
    await _delay();
    var token = _getTokenOrThrow(tokenId);

    if (available) {
      token = token.copyWith(availabilityConfirmed: true);
    } else {
      // Not available: push the token back (e.g. 10 -> 16).
      final newNumber = token.tokenNumber + _shiftBackBy;
      token = token.copyWith(
        tokenNumber: newNumber,
        status: TokenStatus.waiting,
        availabilityConfirmed: false,
        estimatedTime: _estimate(newNumber, token.currentTokenNumber),
      );
    }
    _tokens[tokenId] = token;
    return token;
  }

  @override
  Future<List<ConsultationMessage>> getConsultationMessages(
      String tokenId) async {
    await _delay();
    _getTokenOrThrow(tokenId);
    return List<ConsultationMessage>.from(_chatFor(tokenId));
  }

  @override
  Future<String> sendConsultationMessage({
    required String tokenId,
    required String text,
  }) async {
    await _delay();
    _getTokenOrThrow(tokenId);

    final chat = _chatFor(tokenId);
    chat.add(ConsultationMessage(
      sender: MessageSender.patient,
      text: text,
      timestamp: DateTime.now(),
    ));

    final reply = _ai.reply(tokenId: tokenId, patientText: text);

    chat.add(ConsultationMessage(
      sender: MessageSender.ai,
      text: reply,
      timestamp: DateTime.now(),
    ));
    return reply;
  }

  @override
  Future<String> attachReport({
    required String tokenId,
    required String fileName,
  }) async {
    await _delay();
    _getTokenOrThrow(tokenId);

    final reports = _reports.putIfAbsent(tokenId, () => []);
    if (!reports.contains(fileName)) reports.add(fileName);

    final chat = _chatFor(tokenId);
    chat.add(ConsultationMessage(
      sender: MessageSender.patient,
      text: 'Attached report: $fileName',
      timestamp: DateTime.now(),
      attachmentName: fileName,
    ));

    final reply = _ai.replyToReport(fileName: fileName);

    chat.add(ConsultationMessage(
      sender: MessageSender.ai,
      text: reply,
      timestamp: DateTime.now(),
    ));
    return reply;
  }

  @override
  Future<ConsultationSummary> generateConsultationSummary({
    required String tokenId,
    required String patientName,
  }) async {
    await _delay();
    return _composeSummary(tokenId, patientName);
  }

  @override
  Future<void> saveConsultationSummary(
    String tokenId,
    ConsultationSummary summary,
  ) async {
    await _delay();
    _getTokenOrThrow(tokenId);
    // ONE report per token: saving again replaces the old one.
    _summaries[tokenId] = summary;
  }

  @override
  Future<ConsultationSummary?> getConsultationSummary(String tokenId) async {
    await _delay();
    _getTokenOrThrow(tokenId);
    return _summaries[tokenId];
  }

  @override
  Future<String> getFinalSummary(String tokenId) async {
    await _delay();
    _getTokenOrThrow(tokenId);

    final saved = _summaries[tokenId];
    if (saved != null) return saved.aiSummary;

    if (_patientTexts(tokenId).isEmpty) {
      return 'No consultation messages yet.';
    }
    return _composeSummary(tokenId, 'Patient').aiSummary;
  }
}