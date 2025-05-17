enum MessageType { user, therapist }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.type, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      type:
          map['type'] == MessageType.user.toString()
              ? MessageType.user
              : MessageType.therapist,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
