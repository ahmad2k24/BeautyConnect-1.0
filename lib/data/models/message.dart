class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String type;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    required this.type,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> m) {
    return Message(
      id: m['id'] as String,
      chatId: m['chat_id'] as String,
      senderId: m['sender_id'] as String,
      content: m['content'] as String?,
      type: m['type'] as String? ?? 'text',
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
