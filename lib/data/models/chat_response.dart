class CrisisResources {
  final String? hotline;
  final String? message;
  final List<String>? resources;

  CrisisResources({this.hotline, this.message, this.resources});

  factory CrisisResources.fromJson(Map<String, dynamic> json) {
    return CrisisResources(
      hotline: json['hotline'],
      message: json['message'],
      resources:
          json['resources'] != null
              ? List<String>.from(json['resources'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hotline != null) 'hotline': hotline,
      if (message != null) 'message': message,
      if (resources != null) 'resources': resources,
    };
  }
}

class ChatResponse {
  final String message;
  final String agentType;
  final String conversationId;
  final bool crisisDetected;
  final CrisisResources? crisisResources;
  final List<String>? suggestions;
  final DateTime timestamp;

  ChatResponse({
    required this.message,
    required this.agentType,
    required this.conversationId,
    required this.crisisDetected,
    this.crisisResources,
    this.suggestions,
    required this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'],
      agentType: json['agent_type'],
      conversationId: json['conversation_id'],
      crisisDetected: json['crisis_detected'] ?? false,
      crisisResources:
          json['crisis_resources'] != null
              ? CrisisResources.fromJson(json['crisis_resources'])
              : null,
      suggestions:
          json['suggestions'] != null
              ? List<String>.from(json['suggestions'])
              : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'agent_type': agentType,
      'conversation_id': conversationId,
      'crisis_detected': crisisDetected,
      if (crisisResources != null)
        'crisis_resources': crisisResources!.toJson(),
      if (suggestions != null) 'suggestions': suggestions,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
