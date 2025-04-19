// lib/models/chat_history.dart

class ChatHistory {
  final String id;
  final DateTime timestamp;
  final String title;
  final List<Map<String, String>> messages;

  ChatHistory({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.messages,
  });

  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      title: map['title'],
      messages: List<Map<String, String>>.from(
        (map['messages'] as List).map((message) =>
        Map<String, String>.from(message)
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'messages': messages,
    };
  }
}
