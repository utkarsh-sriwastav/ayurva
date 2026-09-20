/// One presence change: the doctor marking themselves Present or Not Present.
/// The dashboard and attendance screens are both built from these.
class PresenceEvent {
  final DateTime at;
  final bool present;

  const PresenceEvent({required this.at, required this.present});

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        at: DateTime.parse(json['at'] as String),
        present: json['present'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'present': present,
      };
}
