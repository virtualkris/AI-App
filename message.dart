// This file defines the Message model used for chat conversations.

class Message {
  final String id;        // Unique ID for the message
  String text;      // Message content
  final bool isUser;      // true = from user, false = from AI
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  // Converts a Message object to JSON for saving to local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  // Creates a Message object from saved JSON
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
