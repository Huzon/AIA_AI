import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isLoading;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  }) : id = id ?? const Uuid().v4();

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
