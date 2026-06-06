class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isSystem;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isSystem = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'is_user': isUser,
        'is_system': isSystem,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        isUser: json['is_user'] as bool? ?? false,
        isSystem: json['is_system'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
