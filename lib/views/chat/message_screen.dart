import 'package:beauty_connect/data/data.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageScreen extends StatefulWidget {
  final String? otherUserId;
  final String? currentUserId;

  const MessageScreen({super.key, this.otherUserId, this.currentUserId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late final ChatRepository _repo;
  Chat? _thread;
  final List<Message> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _loading = true;
  Map<String, dynamic>? _data = {};
  Future<void> _loadContacts() async {
    final res = await _repo.fetchSingleChatContact(widget.currentUserId!);
    setState(() {
      _data = res;
    });
  }

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository(supabase: Supabase.instance.client);
    _loadContacts();
    _initThread();
  }

  Future<void> _initThread() async {
    final thread = await _repo.getOrCreateThread(
      userA: widget.currentUserId!,
      userB: widget.otherUserId!,
    );
    final history = await _repo.fetchMessages(chatId: thread.id, limit: 50);
    setState(() {
      _thread = thread;
      _messages.clear();
      _messages.addAll(history);
      _loading = false;
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendText() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _thread == null) return;
    final m = await _repo.sendMessage(
      chatId: _thread!.id,
      senderId: widget.currentUserId!,
      content: txt,
    );
    setState(() {
      _messages.add(m);
      _ctrl.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // hides keyboard on tap anywhere
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: -5,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 4,
            children: [
              CircleAvatar(
                backgroundImage: _data != null
                    ? NetworkImage('${_data!['avatar']}')
                    : null,
                child: _data == null ? const CircularProgressIndicator() : null,
              ),
              Text(
                _data != null ? '${_data!['name']}' : 'Loading...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: isDark ? Colors.pink.shade200 : Colors.pink.shade400,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : Column(
                children: [
                  // Chat list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (c, i) {
                        final m = _messages[i];
                        final isMe = m.senderId == widget.currentUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.pink.shade400
                                  : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              m.content ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input field
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _ctrl,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.pinkAccent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade700,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),

                                onSubmitted: (_) => _sendText(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.pink.shade400,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
