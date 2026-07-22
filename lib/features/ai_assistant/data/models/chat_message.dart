/// ChatMessage represents a single message in an AI conversation session.
class ChatMessage {
  final String id;
  final String conversationId;
  final String sender; // 'user', 'ai', 'system'
  final String content;
  final DateTime timestamp;
  final String status; // 'synced', 'pending', 'failed'
  final String? actionType; // optional action tag (e.g. 'health_summary')

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.status = 'synced',
    this.actionType,
  });

  bool get isUser => sender == 'user';
  bool get isAi => sender == 'ai';
  bool get isSystem => sender == 'system';

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? content,
    DateTime? timestamp,
    String? status,
    String? actionType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      actionType: actionType ?? this.actionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'actionType': actionType,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: (json['status'] as String?) ?? 'synced',
      actionType: json['actionType'] as String?,
    );
  }
}
