class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'isLoading': isLoading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      isUser: map['isUser'],
      isLoading: map['isLoading'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
