/// What the mock AI has picked up so far in one consultation.
class ConsultationFacts {
  final List<String> symptoms;
  final String? duration;
  final String? severity;
  final List<String> redFlags;

  const ConsultationFacts({
    required this.symptoms,
    required this.duration,
    required this.severity,
    required this.redFlags,
  });
}

class _ConsultState {
  int patientMessages = 0;
  bool askedDuration = false;
  bool askedSeverity = false;
  bool askedOther = false;
  String? duration;
  String? severity;
  final List<String> symptoms = [];
  final List<String> redFlags = [];
}

/// A simple, rule-based fake "AI" for the prototype.
///
/// - The patient can generate the report after the FIRST message.
///   Nothing here is required: the follow-up questions are optional.
/// - The report always contains the patient's own words, so it works
///   for any symptom in any language. Keyword matching (English +
///   common Hindi/Hinglish words) only adds a short list of symptoms.
/// - It never diagnoses, never suggests medicines, and points
///   emergencies to 112.
///
/// A real AI service will replace this whole file later.
class MockConsultationAi {
  static const String greeting =
      'Hello! I am your pre-consultation assistant. Tell me what problem or '
      'symptoms you have. You can type, use the microphone on your keyboard, '
      'or tap the options below. I only prepare a report for the doctor. '
      'I do not diagnose or suggest medicines.';

  final Map<String, _ConsultState> _states = {};

  // ---- Keyword tables (English + common Hindi/Hinglish words) ----
  static const Map<String, List<String>> _symptomKeywords = {
    'Fever': ['fever', 'temperature', 'bukhar', 'bukhaar'],
    'Cough': ['cough', 'khansi', 'khaansi'],
    'Cold': ['cold', 'runny nose', 'sneez', 'sardi', 'zukam', 'jukam'],
    'Sore throat': ['sore throat', 'throat', 'gala dard', 'gale me dard', 'gale mein dard'],
    'Headache': ['headache', 'head ache', 'head pain', 'sir dard', 'sar dard', 'sirdard', 'sardard', 'sir me dard'],
    'Body pain': ['body pain', 'body ache', 'bodyache', 'muscle pain', 'badan dard', 'badan me dard', 'badan mein dard'],
    'Vomiting': ['vomit', 'nausea', 'ulti', 'ji michla'],
    'Loose motions': ['diarrhea', 'diarrhoea', 'loose motion', 'dast', 'patli potty'],
    'Stomach pain': ['stomach', 'tummy', 'abdom', 'belly', 'pet dard', 'pet me dard', 'pet mein dard'],
    'Breathing difficulty': ['breathing', 'breathless', 'short of breath', 'wheez', 'saans'],
    'Chest pain': ['chest pain', 'chest tightness', 'seene me dard', 'seene mein dard'],
    'Skin problem': ['rash', 'itch', 'skin', 'khujli', 'daane'],
    'Eye problem': ['eye', 'aankh', 'aankhon', 'vision'],
    'Tooth pain': ['tooth', 'daant', 'dant', 'gum pain'],
    'Joint / bone pain': ['joint', 'knee', 'ghutne', 'back pain', 'kamar dard', 'bone', 'haddi'],
    'Dizziness': ['dizz', 'chakkar'],
    'Weakness / tiredness': ['weakness', 'fatigue', 'tired', 'kamzori', 'thakan'],
    'Excess thirst / urination': ['very thirsty', 'excess thirst', 'frequent urination', 'bahut pyas'],
  };

  static const Map<String, List<String>> _redFlagKeywords = {
    'Chest pain': ['chest pain', 'chest tightness', 'seene me dard', 'seene mein dard'],
    'Difficulty breathing': [
      'difficulty breathing',
      'breathing difficulty',
      'breathing problem',
      'trouble breathing',
      'breathless',
      'short of breath',
      'shortness of breath',
      "can't breathe",
      'cant breathe',
      'cannot breathe',
      'saans nahi',
      'saans lene me',
      'saans phool',
    ],
    'Fainting / unconsciousness': ['faint', 'unconscious', 'passed out', 'blacked out', 'behosh'],
    'Seizure': ['seizure', 'convulsion', 'daura'],
    'Severe bleeding': [
      'severe bleeding',
      'heavy bleeding',
      'bleeding a lot',
      'vomiting blood',
      'blood in stool',
      'coughing blood',
      'khoon ki ulti',
    ],
    'Stroke warning signs': ['face drooping', 'slurred speech', 'sudden weakness', 'paralysis'],
    'Thoughts of self-harm': ['suicide', 'suicidal', 'kill myself', 'end my life', 'self harm', 'self-harm'],
  };

  // ---- Public methods used by the mock repository ----

  /// Returns the AI reply to one patient message.
  String reply({required String tokenId, required String patientText}) {
    final state = _states.putIfAbsent(tokenId, () => _ConsultState());
    final text = patientText.toLowerCase();
    state.patientMessages++;

    // 1. Safety first: look for emergency warning signs.
    final flagsNow = _findMatches(text, _redFlagKeywords);
    for (final flag in flagsNow) {
      if (!state.redFlags.contains(flag)) state.redFlags.add(flag);
    }

    // 2. Pick up symptoms, duration and severity from this message.
    _learnFrom(state, text);

    if (flagsNow.isNotEmpty) return _emergencyReply(flagsNow);

    // 3. Optional follow-up. The patient can always generate the report.
    return _followUp(state);
  }

  /// Returns the AI reply when the patient attaches a report.
  String replyToReport({required String fileName}) {
    return 'I have noted your report ($fileName) and will add it to your summary.';
  }

  /// What the AI has picked up so far for this token.
  ConsultationFacts factsFor(String tokenId) {
    final state = _states[tokenId];
    if (state == null) {
      return const ConsultationFacts(
        symptoms: [],
        duration: null,
        severity: null,
        redFlags: [],
      );
    }
    return ConsultationFacts(
      symptoms: List<String>.from(state.symptoms),
      duration: state.duration,
      severity: state.severity,
      redFlags: List<String>.from(state.redFlags),
    );
  }

  /// Writes the summary text. It is based on the patient's own words,
  /// so it is never empty, whatever symptoms the patient describes.
  String buildSummaryText({
    required String patientName,
    required int tokenNumber,
    required String doctor,
    required String specialty,
    required ConsultationFacts facts,
    required List<String> patientWords,
    required List<String> reports,
  }) {
    final parts = <String>[];

    parts.add('$patientName has token $tokenNumber to see $doctor ($specialty).');

    if (patientWords.isEmpty) {
      parts.add('The patient has not described the problem yet.');
    } else {
      parts.add('The patient says: "${_shorten(patientWords.first)}".');
      final more = patientWords.skip(1).take(3).toList();
      if (more.isNotEmpty) {
        final quoted = more.map((w) => '"${_shorten(w)}"').join(', ');
        parts.add('Further details: $quoted.');
      }
    }

    if (facts.symptoms.isNotEmpty) {
      parts.add('Symptoms noted: ${facts.symptoms.join(', ').toLowerCase()}.');
    }

    final duration = facts.duration;
    if (duration != null) parts.add('Duration: $duration.');

    final severity = facts.severity;
    if (severity != null) parts.add('Severity: $severity.');

    if (reports.isNotEmpty) {
      parts.add('Reports attached: ${reports.join(', ')}.');
    }

    parts.add(facts.redFlags.isEmpty
        ? 'No red flags were mentioned.'
        : 'Red flags mentioned: ${facts.redFlags.join(', ').toLowerCase()}. Please review urgently.');

    parts.add(
        "This is a pre-consultation note based on the patient's own words. It is not a diagnosis.");
    return parts.join(' ');
  }

  // ---- Optional follow-up questions ----

  String _followUp(_ConsultState state) {
    final opening =
        state.patientMessages == 1 ? 'Thanks, I have noted your problem.' : 'Noted.';
    const generate = 'You can tap "Generate Summary" any time.';

    if (state.duration == null && !state.askedDuration) {
      state.askedDuration = true;
      final ask = state.severity == null
          ? 'since when you have this, and how severe it is (mild, moderate or severe)'
          : 'since when you have this';
      return '$opening If you like, tell me $ask. $generate';
    }

    if (state.severity == null && !state.askedSeverity) {
      state.askedSeverity = true;
      return '$opening How severe is it (mild, moderate or severe, or a score from 1 to 10)? $generate';
    }

    if (!state.askedOther) {
      state.askedOther = true;
      return '$opening Do you have any other symptoms the doctor should know about? $generate';
    }

    return '$opening I have added this to your notes. $generate';
  }

  String _emergencyReply(List<String> flags) {
    if (flags.contains('Thoughts of self-harm')) {
      return 'I am really sorry you are going through this. Your safety matters most right now. '
          'Please contact someone you trust, and call 112 or go to the nearest hospital emergency department immediately. '
          'I am not able to provide emergency help.';
    }
    return 'What you describe (${flags.join(', ').toLowerCase()}) can be serious. '
        'Please do not wait for this consultation: call 112 (or 108 for an ambulance) or go to the nearest emergency department right away. '
        'I am an assistant, not a doctor, and I cannot assess emergencies.';
  }

  // ---- Reading the patient's messages ----

  void _learnFrom(_ConsultState state, String text) {
    for (final symptom in _findMatches(text, _symptomKeywords)) {
      if (!state.symptoms.contains(symptom)) state.symptoms.add(symptom);
    }
    state.duration ??= _findDuration(text);
    state.severity ??= _findSeverity(text);
  }

  // Ignores a keyword that comes right after "no", "not", "without", etc.
  static final RegExp _negation = RegExp(
      r"(^|\s)(no|not|without|never|dont|don't)\s+(have\s+|having\s+|had\s+|got\s+)?(any\s+|a\s+)?$");

  bool _mentions(String text, String keyword) {
    var index = text.indexOf(keyword);
    while (index != -1) {
      final before = text.substring(0, index);
      if (!_negation.hasMatch(before)) return true;
      index = text.indexOf(keyword, index + keyword.length);
    }
    return false;
  }

  List<String> _findMatches(String text, Map<String, List<String>> table) {
    final found = <String>[];
    for (final entry in table.entries) {
      for (final keyword in entry.value) {
        if (_mentions(text, keyword)) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found;
  }

  static final RegExp _durationPattern = RegExp(
      r'\b(\d+|a|an|one|two|three|four|five|six|seven|eight|nine|ten|few|couple of|ek|do|teen|char|paanch)\s*(hours?|hrs?|ghante|ghanta|days?|din|weeks?|hafte|hafta|months?|mahine|mahina|years?|saal|sal)\b(?!\s+old)');

  String? _findDuration(String text) {
    final match = _durationPattern.firstMatch(text);
    if (match != null) return match.group(0);
    if (text.contains('yesterday') || text.contains('kal se')) {
      return 'since yesterday';
    }
    if (text.contains('last night') || text.contains('raat se')) {
      return 'since last night';
    }
    if (text.contains('this morning') ||
        text.contains('since morning') ||
        text.contains('subah se') ||
        text.contains('aaj subah')) {
      return 'since this morning';
    }
    if (text.contains('last week')) return 'since last week';
    if (text.contains('last month')) return 'since last month';
    if (text.contains('today') || text.contains('aaj')) return 'since today';
    return null;
  }

  static final RegExp _scorePattern =
      RegExp(r'\b(\d{1,2})\s*(?:/|out of)\s*10\b');

  String? _findSeverity(String text) {
    final match = _scorePattern.firstMatch(text);
    if (match != null) return '${match.group(1)}/10';
    if (_mentions(text, 'mild') ||
        _mentions(text, 'halka') ||
        _mentions(text, 'halki')) {
      return 'Mild';
    }
    if (_mentions(text, 'moderate') || _mentions(text, 'medium')) {
      return 'Moderate';
    }
    if (_mentions(text, 'severe') ||
        _mentions(text, 'unbearable') ||
        _mentions(text, 'very bad') ||
        _mentions(text, 'bahut tez') ||
        _mentions(text, 'bahut zyada') ||
        _mentions(text, 'bahut jyada') ||
        _mentions(text, 'asahniya')) {
      return 'Severe';
    }
    return null;
  }

  String _shorten(String text, [int maxLength = 150]) {
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }
}