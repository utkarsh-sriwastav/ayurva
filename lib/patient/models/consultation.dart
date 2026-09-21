/// Who sent a chat message in the AI consultation.
enum MessageSender { patient, ai }

class ConsultationMessage {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  const ConsultationMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}