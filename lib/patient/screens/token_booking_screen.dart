import 'package:flutter/material.dart';

import '../data/patient_repository.dart';
import '../models/doctor_option.dart';
import '../models/token.dart';

/// Book a token: Hospital -> Problem -> Doctor -> Token.
class TokenBookingScreen extends StatefulWidget {
  /// Phone number of the patient. The Patient Home screen does not
  /// know it yet, so a placeholder is used for the prototype.
  final String patientPhone;

  const TokenBookingScreen({super.key, this.patientPhone = '9999999999'});

  @override
  State<TokenBookingScreen> createState() => _TokenBookingScreenState();
}

class _TokenBookingScreenState extends State<TokenBookingScreen> {
  bool _isLoadingInitial = true;
  List<Hospital> _hospitals = [];
  List<DiseaseOption> _diseases = [];

  Hospital? _selectedHospital;
  DiseaseOption? _selectedDisease;

  bool _isLoadingDoctors = false;
  List<DoctorOption> _doctors = [];
  DoctorOption? _selectedDoctor;

  bool _isBooking = false;
  Token? _token;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final hospitals = await PatientRepository.instance.getHospitals();
    final diseases = await PatientRepository.instance.getDiseases();
    if (!mounted) return;
    setState(() {
      _hospitals = hospitals;
      _diseases = diseases;
      _isLoadingInitial = false;
    });
  }

  void _onHospitalChanged(String? hospitalId) {
    if (hospitalId == null) return;
    final hospital = _hospitals.firstWhere((h) => h.id == hospitalId);
    setState(() {
      _selectedHospital = hospital;
      // Changing the hospital resets everything after it.
      _selectedDisease = null;
      _doctors = [];
      _selectedDoctor = null;
      _isLoadingDoctors = false;
    });
  }

  Future<void> _onDiseaseSelected(DiseaseOption disease) async {
    final hospital = _selectedHospital;
    if (hospital == null) return;

    setState(() {
      _selectedDisease = disease;
      _selectedDoctor = null;
      _doctors = [];
      _isLoadingDoctors = true;
    });

    // The disease decides the specialty; the repository returns only
    // AVAILABLE doctors of that specialty in this hospital.
    final doctors = await PatientRepository.instance.getAvailableDoctors(
      hospitalId: hospital.id,
      specialty: disease.specialty,
    );
    if (!mounted) return;

    // Ignore this answer if the patient already picked something else.
    if (_selectedDisease != disease || _selectedHospital != hospital) return;

    setState(() {
      _doctors = doctors;
      _isLoadingDoctors = false;
    });
  }

  Future<void> _handleGetToken() async {
    final doctor = _selectedDoctor;
    if (doctor == null) return;

    setState(() => _isBooking = true);

    try {
      final token = await PatientRepository.instance.requestToken(
        doctorId: doctor.id,
        patientPhone: widget.patientPhone,
        problem: _selectedDisease?.name,
      );
      if (!mounted) return;
      setState(() {
        _token = token;
        _isBooking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;

    return Scaffold(
      appBar: AppBar(title: Text(token == null ? 'Book Token' : 'Your Token')),
      body: SafeArea(
        child: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : token != null
                ? _buildTokenResult(token)
                : _buildBookingForm(),
      ),
    );
  }

  // ---------------- Booking form ----------------

  Widget _buildBookingForm() {
    final disease = _selectedDisease;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('1. Select hospital'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Hospital',
              prefixIcon: Icon(Icons.local_hospital_outlined),
              border: OutlineInputBorder(),
            ),
            items: _hospitals
                .map((h) => DropdownMenuItem<String>(
                      value: h.id,
                      child: Text(h.name),
                    ))
                .toList(),
            onChanged: _onHospitalChanged,
          ),
          if (_selectedHospital != null) ...[
            const SizedBox(height: 24),
            _sectionTitle('2. What is the problem?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diseases
                  .map((d) => ChoiceChip(
                        label: Text(d.name),
                        selected: _selectedDisease == d,
                        onSelected: (_) => _onDiseaseSelected(d),
                      ))
                  .toList(),
            ),
          ],
          if (disease != null) ...[
            const SizedBox(height: 16),
            Text(
              'Required specialty: ${disease.specialty}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _sectionTitle('3. Choose an available doctor'),
            _buildDoctorList(),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed:
                (_selectedDoctor == null || _isBooking) ? null : _handleGetToken,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Get Token'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_isLoadingDoctors) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No doctor is currently available for this problem at this hospital.',
          style: TextStyle(color: Colors.amber.shade900),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: _doctors.map((doctor) {
        final selected = _selectedDoctor?.id == doctor.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(doctor.name),
            subtitle: Text(doctor.specialty),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? primary : null,
            ),
            selected: selected,
            onTap: () => setState(() => _selectedDoctor = doctor),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- Token result ----------------

  Widget _buildTokenResult(Token token) {
    final doctor = _selectedDoctor;
    final waiting = token.estimatedTime.difference(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Token number',
                    style: TextStyle(color: Colors.black54),
                  ),
                  Text(
                    '${token.tokenNumber}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),
                  _infoRow('Doctor', doctor?.name ?? '-'),
                  _infoRow('Hospital', _selectedHospital?.name ?? '-'),
                  _infoRow('Specialty', doctor?.specialty ?? '-'),
                  _infoRow('Current token', '${token.currentTokenNumber}'),
                  _infoRow('Patients ahead', '${token.patientsAhead}'),
                  _infoRow(
                    'Estimated time',
                    TimeOfDay.fromDateTime(token.estimatedTime).format(context),
                  ),
                  _infoRow('Estimated waiting', _formatWaiting(waiting)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  String _formatWaiting(Duration duration) {
    final minutes = (duration.inSeconds / 60).round();
    if (minutes <= 0) return 'Your turn is near';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }
}