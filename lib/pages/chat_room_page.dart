import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at');

    setState(() {
      messages = res
          .where(
            (msg) =>
                (msg['sender_id'] == userId &&
                    msg['receiver_id'] == widget.receiverId) ||
                (msg['sender_id'] == widget.receiverId &&
                    msg['receiver_id'] == userId),
          )
          .toList();
    });

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _subscribeToMessages() {
    final userId = supabase.auth.currentUser!.id;

    supabase
        .channel('realtime:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            column: 'receiver_id',
            type: PostgresChangeFilterType.eq,
            value: userId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (newMessage['sender_id'] == widget.receiverId) {
              setState(() {
                messages.add(newMessage);
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = supabase.auth.currentUser!.id;

    await supabase.from('messages').insert({
      'sender_id': userId,
      'receiver_id': widget.receiverId,
      'content': text,
    });

    _messageController.clear();
    await _loadMessages(); // 可选：手动刷新一次
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final userId = supabase.auth.currentUser!.id;
    final isMe = msg['sender_id'] == userId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg['content'],
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
