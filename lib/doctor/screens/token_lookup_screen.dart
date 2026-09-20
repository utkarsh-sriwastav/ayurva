import 'package:flutter/material.dart';

import '../data/doctor_repository.dart';
import '../models/patient_history.dart';
import '../models/queue_patient.dart';

/// Doctor enters a token number, reads that patient's history, generates the
/// AI summary for review, and can mark the consultation as checked.
///
/// Pops `true` when anything changed, so the caller refreshes its counters.
class TokenLookupScreen extends StatefulWidget {
  /// Opening from the queue list pre-fills and auto-searches this token.
  final int? initialToken;

  const TokenLookupScreen({super.key, this.initialToken});

  @override
  State<TokenLookupScreen> createState() => _TokenLookupScreenState();
}

class _TokenLookupScreenState extends State<TokenLookupScreen> {
  final _controller = TextEditingController();

  PatientHistory? _history;
  ConsultationStatus? _status;
  bool _isSearching = false;
  bool _isGenerating = false;
  bool _isMarking = false;
  String? _message;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _controller.text = widget.initialToken.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final number = int.tryParse(_controller.text.trim());
    if (number == null) {
      setState(() => _message = 'Enter a valid token number.');
      return;
    }

    setState(() {
      _isSearching = true;
      _message = null;
      _history = null;
      _status = null;
    });

    final repo = DoctorRepository.instance;
    final history = await repo.getPatientHistory(number);
    ConsultationStatus? status;
    if (history != null) {
      final queue = await repo.getTodayQueue('');
      for (final p in queue) {
        if (p.tokenNumber == number) status = p.status;
      }
    }

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _history = history;
      _status = status;
      if (history == null) {
        _message = 'No active token #$number today. '
            'Tokens expire at the end of the day.';
      }
    });
  }

  Future<void> _generateSummary() async {
    final history = _history;
    if (history == null) return;

    setState(() => _isGenerating = true);
    final summary =
        await DoctorRepository.instance.generateAiSummary(history.tokenNumber);

    if (!mounted) return;
    setState(() {
      _history = history.copyWith(aiSummary: summary);
      _isGenerating = false;
    });
  }

  Future<void> _markChecked() async {
    final history = _history;
    if (history == null) return;

    setState(() => _isMarking = true);
    final updated =
        await DoctorRepository.instance.markChecked(history.tokenNumber);

    if (!mounted) return;
    setState(() {
      _status = updated.status;
      _isMarking = false;
      _didChange = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token #${updated.tokenNumber} marked as checked.'),
      ),
    );
  }

  static String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final isChecked = _status == ConsultationStatus.checked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient history'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _didChange),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'Token number',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isSearching ? null : _search,
                    child: _isSearching
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Open'),
                  ),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (history != null) ...[
              const SizedBox(height: 20),
              _PatientHeader(history: history, isChecked: isChecked),
              const SizedBox(height: 16),
              _Section(
                title: 'Background',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(
                      label: 'Chronic conditions',
                      value: history.chronicConditions.isEmpty
                          ? 'None reported'
                          : history.chronicConditions.join(', '),
                    ),
                    _Line(
                      label: 'Allergies',
                      value: history.allergies.isEmpty
                          ? 'None reported'
                          : history.allergies.join(', '),
                    ),
                    _Line(label: 'Blood group', value: history.bloodGroup),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Past visits',
                child: history.visits.isEmpty
                    ? const Text('No earlier visits on record.',
                        style: TextStyle(color: Colors.black54))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: history.visits
                            .map((v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_dateLabel(v.date)} \u2022 '
                                        '${v.department}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(v.diagnosis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(v.prescription,
                                          style:
                                              const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              if (history.aiSummary == null)
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateSummary,
                  icon: _isGenerating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.smart_toy_outlined),
                  label: Text(_isGenerating
                      ? 'Generating summary...'
                      : 'Generate AI summary'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )
              else
                _Section(
                  title: 'AI summary for doctor review',
                  child: SelectableText(
                    history.aiSummary!,
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isChecked || _isMarking ? null : _markChecked,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(isChecked
                    ? '\u2713 Checked'
                    : 'Mark as checked'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  final PatientHistory history;
  final bool isChecked;

  const _PatientHeader({required this.history, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Token #${history.tokenNumber}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer)),
              if (isChecked)
                const Icon(Icons.verified, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(history.patientName,
              style: TextStyle(fontSize: 18, color: scheme.onPrimaryContainer)),
          const SizedBox(height: 4),
          Text(
            '${history.age} yrs \u2022 ${history.gender} \u2022 '
            '${history.heightCm.toStringAsFixed(0)} cm \u2022 '
            '${history.weightKg.toStringAsFixed(0)} kg \u2022 '
            'BMI ${history.bmi.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
