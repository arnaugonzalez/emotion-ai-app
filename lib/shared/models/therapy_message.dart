class TherapyMessage {
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;

  TherapyMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TherapyMessage.fromMap(Map<String, dynamic> map) {
    return TherapyMessage(
      content: map['content'],
      role: map['role'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // Create a message from user input
  factory TherapyMessage.fromUser(String content) {
    return TherapyMessage(content: content, role: 'user');
  }

  // Create a message from AI response
  factory TherapyMessage.fromAssistant(String content) {
    return TherapyMessage(content: content, role: 'assistant');
  }
}
