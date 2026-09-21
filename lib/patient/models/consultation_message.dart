/// Who sent a chat message in the AI consultation.
enum MessageSender { patient, ai }

class ConsultationMessage {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  /// File name if this message is an attached report, otherwise null.
  final String? attachmentName;

  const ConsultationMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.attachmentName,
  });
}