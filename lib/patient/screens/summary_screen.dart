import 'package:flutter/material.dart';

import '../data/patient_repository.dart';
import '../models/consultation_summary.dart';

/// The one-page AI pre-consultation report for one token. Read-only.
/// The Doctor side reads this same report using the same token ID.
class SummaryScreen extends StatefulWidget {
  final String tokenId;

  const SummaryScreen({super.key, required this.tokenId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  String? _error;
  ConsultationSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await PatientRepository.instance
          .getConsultationSummary(widget.tokenId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the report: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Consultation Report')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _centerText(_error!)
                : summary == null
                    ? _centerText(
                        'No report yet. Go back to the AI Consultant and tap Generate Summary.')
                    : _buildReport(summary),
      ),
    );
  }

  Widget _centerText(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildReport(ConsultationSummary s) {
    final created = s.createdAt;
    final generatedOn =
        '${created.day}/${created.month}/${created.year}, ${TimeOfDay.fromDateTime(created).format(context)}';
    final problemAndSpecialty =
        s.problem == null ? s.specialty : '${s.problem} / ${s.specialty}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Pre-Consultation Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Generated on $generatedOn',
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                const Divider(height: 28),
                _infoRow('Patient', s.patientName),
                _infoRow('Token number', '${s.tokenNumber}'),
                _infoRow('Hospital', s.hospital),
                _infoRow('Doctor', s.doctor),
                _infoRow('Problem / Specialty', problemAndSpecialty),
                const Divider(height: 28),
                _title('What the patient said'),
                ..._patientWords(s),
                const SizedBox(height: 16),
                _title('Symptoms noted'),
                _chipsOrText(
                  s.symptoms,
                  "Not picked up automatically. See the patient's own words above.",
                ),
                const SizedBox(height: 12),
                _infoRow('Duration', s.duration ?? 'Not stated'),
                _infoRow('Severity', s.severity ?? 'Not stated'),
                const SizedBox(height: 12),
                _title('Reports attached'),
                _reportsList(s.reports),
                const Divider(height: 28),
                _title('AI-generated summary'),
                Text(s.aiSummary, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 16),
                _redFlagsBox(s.redFlags),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Saved for ${s.doctor} under token ${s.tokenNumber}.\n'
            'This AI-generated summary is for pre-consultation assistance '
            'and should be reviewed by a qualified doctor. It is not a '
            'diagnosis.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _patientWords(ConsultationSummary s) {
    if (s.patientWords.isEmpty) {
      return [const Text('The patient did not type anything.')];
    }
    return [
      Text(
        '"${s.patientWords.first}"',
        style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4),
      ),
      for (final word in s.patientWords.skip(1))
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('- $word', style: const TextStyle(height: 1.4)),
        ),
    ];
  }

  Widget _chipsOrText(List<String> items, String emptyText) {
    if (items.isEmpty) return Text(emptyText);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items.map((item) => Chip(label: Text(item))).toList(),
    );
  }

  Widget _reportsList(List<String> reports) {
    if (reports.isEmpty) return const Text('No reports attached');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reports
          .map((name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18),
                    const SizedBox(width: 8),
                    Flexible(child: Text(name)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _redFlagsBox(List<String> redFlags) {
    final hasFlags = redFlags.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasFlags ? Colors.red.shade50 : Colors.green.shade50,
        border: Border.all(
          color: hasFlags ? Colors.red.shade200 : Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important notes / red flags',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (!hasFlags)
            const Text(
              'No red flags were mentioned. This does not rule out a medical problem.',
            )
          else
            for (final flag in redFlags)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(flag)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}