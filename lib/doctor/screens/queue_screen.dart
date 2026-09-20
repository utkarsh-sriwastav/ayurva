import 'package:flutter/material.dart';

import '../data/doctor_repository.dart';
import '../models/queue_patient.dart';
import '../widgets/status_chip.dart';
import 'token_lookup_screen.dart';

/// Today's patient queue with Waiting / In consultation / Checked status and
/// the Mark as Checked action.
class QueueScreen extends StatefulWidget {
  final String doctorId;

  const QueueScreen({super.key, required this.doctorId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<QueuePatient> _queue = const [];
  bool _isLoading = true;
  int? _busyToken;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final queue = await DoctorRepository.instance.getTodayQueue(widget.doctorId);
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _isLoading = false;
    });
  }

  Future<void> _start(QueuePatient patient) async {
    setState(() => _busyToken = patient.tokenNumber);
    await DoctorRepository.instance.startConsultation(patient.tokenNumber);
    if (!mounted) return;
    _didChange = true;
    setState(() => _busyToken = null);
    await _load();
  }

  Future<void> _markChecked(QueuePatient patient) async {
    setState(() => _busyToken = patient.tokenNumber);
    await DoctorRepository.instance.markChecked(patient.tokenNumber);
    if (!mounted) return;
    _didChange = true;
    setState(() => _busyToken = null);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token #${patient.tokenNumber} marked as checked.'),
      ),
    );
  }

  Future<void> _openHistory(QueuePatient patient) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TokenLookupScreen(initialToken: patient.tokenNumber),
      ),
    );
    if (changed == true) _didChange = true;
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final checked =
        _queue.where((p) => p.status == ConsultationStatus.checked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's queue"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _didChange),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '$checked of ${_queue.length} patients checked today',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ..._queue.map((patient) {
                      final isBusy = _busyToken == patient.tokenNumber;
                      final isChecked =
                          patient.status == ConsultationStatus.checked;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isChecked
                                        ? Colors.green.shade100
                                        : Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                    child: Text('${patient.tokenNumber}'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(patient.patientName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                          '${patient.age} yrs \u2022 '
                                          '${patient.gender}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(status: patient.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openHistory(patient),
                                      icon: const Icon(Icons.description_outlined,
                                          size: 18),
                                      label: const Text('History'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: isChecked
                                        ? const OutlinedButton(
                                            onPressed: null,
                                            child: Text('\u2713 Checked'),
                                          )
                                        : FilledButton(
                                            onPressed: isBusy
                                                ? null
                                                : () => patient.status ==
                                                        ConsultationStatus
                                                            .waiting
                                                    ? _start(patient)
                                                    : _markChecked(patient),
                                            child: isBusy
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : Text(patient.status ==
                                                        ConsultationStatus
                                                            .waiting
                                                    ? 'Start'
                                                    : 'Mark as checked'),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
