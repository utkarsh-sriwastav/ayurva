/// The logged-in doctor. [isPresent] is the presence flag - patients can only
/// pull tokens while it is true. [statusChangedAt] records when the doctor
/// last switched between Present and Not Present.
class DoctorProfile {
  final String id;
  final String name;
  final String department;
  final String phone;
  final bool isPresent;
  final DateTime? statusChangedAt;

  const DoctorProfile({
    required this.id,
    required this.name,
    required this.department,
    required this.phone,
    required this.isPresent,
    this.statusChangedAt,
  });

  String get statusLabel => isPresent ? 'Present' : 'Not Present';

  DoctorProfile copyWith({bool? isPresent, DateTime? statusChangedAt}) =>
      DoctorProfile(
        id: id,
        name: name,
        department: department,
        phone: phone,
        isPresent: isPresent ?? this.isPresent,
        statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      );

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String,
        phone: json['phone'] as String,
        isPresent: json['is_present'] as bool,
        statusChangedAt: json['status_changed_at'] == null
            ? null
            : DateTime.parse(json['status_changed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'phone': phone,
        'is_present': isPresent,
        'status_changed_at': statusChangedAt?.toIso8601String(),
      };
}
