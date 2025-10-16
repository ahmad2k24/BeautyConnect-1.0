import 'package:beauty_connect/data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatRepository {
  final SupabaseClient supabase;
  final Uuid _uuid = const Uuid();

  ChatRepository({required this.supabase});

  Future<Chat?> findThread(String userA, String userB) async {
    final user1 = (userA.compareTo(userB) < 0) ? userA : userB;
    final user2 = (userA.compareTo(userB) < 0) ? userB : userA;

    final res = await supabase
        .from('chats')
        .select()
        .eq('user1', user1)
        .eq('user2', user2)
        .maybeSingle();

    return res != null ? Chat.fromMap(res) : null;
  }

  Future<List<Chat>> fetchThreadsForUser(String currentUserId) async {
    final res = await supabase
        .from('chats')
        .select()
        .or('user1.eq.$currentUserId,user2.eq.$currentUserId')
        .order('created_at');

    return (res as List).map((e) => Chat.fromMap(e)).toList();
  }

  Future<Chat> getOrCreateThread({
    required String userA,
    required String userB,
    Chat? chat,
  }) async {
    final user1 = (userA.compareTo(userB) < 0) ? userA : userB;
    final user2 = (userA.compareTo(userB) < 0) ? userB : userA;

    final res = await supabase
        .from('chats')
        .select()
        .eq('user1', user1)
        .eq('user2', user2)
        .limit(1)
        .maybeSingle();

    if (res != null) return Chat.fromMap(res);

    final createRes = await supabase
        .from('chats')
        .insert({
          'user1': user1,
          'user2': user2,
          'user1_name': chat?.user1Name ?? '',
          'user2_name': chat?.user2Name ?? '',
          'user1_avatar': chat?.user1Avatar ?? '',
          'user2_avatar': chat?.user2Avatar ?? '',
        })
        .select()
        .maybeSingle();

    if (createRes == null) throw Exception('Failed to create thread');

    return Chat.fromMap(createRes);
  }

  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    String? content,
    String type = 'text',
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'type': type,
    };

    final insert = await supabase
        .from('messages')
        .insert(payload)
        .select()
        .maybeSingle();

    if (insert == null) throw Exception('Failed to insert message');

    return Message.fromMap(insert);
  }

  Future<List<Message>> fetchMessages({
    required String chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final list = (res as List).map((e) => Message.fromMap(e)).toList();
    return list.reversed.toList();
  }

  /// Fetch only ONE contact (name + avatar) for given user
  Future<Map<String, String>?> fetchSingleChatContact(String userId) async {
    try {
      final response = await supabase
          .from('chats')
          .select(
            'user1, user2, user1_name, user2_name, user1_avatar, user2_avatar',
          )
          .or('user1.eq.$userId,user2.eq.$userId')
          .limit(1)
          .maybeSingle(); // returns null if no row found

      if (response == null) return null;

      final isUser1 = response['user1'] == userId;

      return {
        'name': isUser1
            ? response['user2_name'] as String
            : response['user1_name'] as String,
        'avatar': isUser1
            ? response['user2_avatar'] as String
            : response['user1_avatar'] as String,
      };
    } catch (e) {
      print('❌ Error fetching single contact: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      // First check in clients table
      final clientResponse = await supabase
          .from('clients')
          .select('name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (clientResponse != null) {
        return {
          'name': clientResponse['name'],
          'url': clientResponse['avatar_url'],
        };
      }

      // Then check in vendors table
      final vendorResponse = await supabase
          .from('vendors')
          .select('name, vendor_url')
          .eq('id', userId)
          .maybeSingle();

      if (vendorResponse != null) {
        return {
          'name': vendorResponse['name'],
          'url': vendorResponse['vendor_url'],
        };
      }

      throw Exception('User not found in clients or vendors');
    } catch (e) {
      print('Error fetching user details: $e');
      rethrow;
    }
  }
}
