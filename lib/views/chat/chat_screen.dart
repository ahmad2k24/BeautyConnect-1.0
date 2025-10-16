import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  const ChatScreen({super.key, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRepository _repo;
  List<Chat> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository(supabase: Supabase.instance.client);
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() => _loading = true);
    final threads = await _repo.fetchThreadsForUser(widget.currentUserId);
    setState(() {
      _threads = threads;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conversations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.pink.shade200 : Colors.pink.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _threads.isEmpty
          ? Center(
              child: Text(
                'No conversations yet 💬',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _threads.length,
              itemBuilder: (context, i) {
                final t = _threads[i];
                final isCurrentUserUser1 = t.user1 == widget.currentUserId;

                final otherUserId = isCurrentUserUser1 ? t.user2 : t.user1;
                final otherUserName = isCurrentUserUser1
                    ? t.user2Name
                    : t.user1Name;
                final otherUserAvatar = isCurrentUserUser1
                    ? t.user2Avatar
                    : t.user1Avatar;
                print(
                  'other user ID : $otherUserId /n other user Name : $otherUserName /n other user Avatar: $otherUserAvatar',
                );
                return Card(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.pink.shade100,
                      backgroundImage: otherUserAvatar.isNotEmpty
                          ? NetworkImage(otherUserAvatar)
                          : null,
                      child: otherUserAvatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    ),
                    title: Text(
                      otherUserName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.pink.shade300,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tap to open conversation',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageScreen(
                            otherUserId: otherUserId,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
