import 'chat_message.dart';

/// ChatConversation represents a persistent conversation thread for a patient.
class ChatConversation {
  final String id;
  final int patientId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.id,
    required this.patientId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  ChatConversation copyWith({
    String? id,
    int? patientId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List? ?? [];
    return ChatConversation(
      id: json['id'] as String,
      patientId: json['patientId'] as int,
      title: (json['title'] as String?) ?? 'Health Chat',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: rawMessages
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
