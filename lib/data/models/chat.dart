class Chat {
  final String id;
  final String user1;
  final String user2;
  final String user1Name;
  final String user2Name;
  final String user1Avatar;
  final String user2Avatar;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.user1,
    required this.user2,
    required this.createdAt,
    required this.user1Name,
    required this.user2Name,
    required this.user1Avatar,
    required this.user2Avatar,
  });

  factory Chat.fromMap(Map<String, dynamic> m) {
    return Chat(
      id: m['id'] as String,
      user1: m['user1'] as String,
      user2: m['user2'] as String,
      user1Name: m['user1_name'] as String,
      user2Name: m['user2_name'] as String,
      user1Avatar: m['user1_avatar'] as String,
      user2Avatar: m['user2_avatar'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
