/// A hospital the patient can book a token in.
class Hospital {
  final String id;
  final String name;

  const Hospital({required this.id, required this.name});
}

/// A disease/problem the patient can choose, and the medical
/// specialty that treats it.
class DiseaseOption {
  final String name;
  final String specialty;

  const DiseaseOption({required this.name, required this.specialty});
}

/// A doctor shown to the patient while booking a token.
class DoctorOption {
  final String id;
  final String name;
  final String hospitalId;
  final String specialty;
  final bool available;

  const DoctorOption({
    required this.id,
    required this.name,
    required this.hospitalId,
    required this.specialty,
    required this.available,
  });
}