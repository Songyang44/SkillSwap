import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    if (user == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final convoResponse = await supabase
          .from('conversations')
          .select('id, user1_id, user2_id, created_at')
          .or('user1_id.eq.${user!.id},user2_id.eq.${user!.id}')
          .order('created_at', ascending: false);

      // 确保 convoResponse 是 List，如果是单个 Map 就包成 List
      List<Map<String, dynamic>> convoList = List<Map<String, dynamic>>.from(
        convoResponse,
      );
      ;
      if (convoResponse is List) {
        convoList = List<Map<String, dynamic>>.from(convoResponse);
      } else if (convoResponse is Map) {
        convoList = [Map<String, dynamic>.from(convoResponse as Map)];
      } else {
        convoList = [];
      }

      if (convoList.isEmpty) {
        setState(() {
          conversations = [];
          isLoading = false;
        });
        return;
      }

      final partnerIds = convoList
          .map((c) {
            return c['user1_id'] == user!.id ? c['user2_id'] : c['user1_id'];
          })
          .toSet()
          .toList();

      if (partnerIds.isEmpty) {
        setState(() {
          conversations = [];
          isLoading = false;
        });
        return;
      }

      final userResponse = await supabase
          .from('user')
          .select('id, name, avatar_url')
          .filter('id', 'in', partnerIds);

      // 确保 userResponse 是 List，如果是单个 Map 就包成 List
      List<Map<String, dynamic>> userList = [];

      if (userResponse is List) {
        userList = userResponse
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (userResponse is Map) {
        userList = [Map<String, dynamic>.from(userResponse as Map)];
      } else {
        userList = [];
      }

      final userMap = <String, Map<String, dynamic>>{};
      for (var u in userList) {
        if (u['id'] != null) {
          userMap[u['id']] = u;
        }
      }

      final result = convoList.map((c) {
        final partnerId = c['user1_id'] == user!.id
            ? c['user2_id']
            : c['user1_id'];
        final partnerInfo = userMap[partnerId];
        return {
          'conversation_id': c['id'],
          'user_id': partnerInfo?['id'],
          'name': partnerInfo?['name'] ?? 'Unknown',
          'avatar_url': partnerInfo?['avatar_url'],
          'created_at': c['created_at'],
        };
      }).toList();

      setState(() {
        conversations = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to fetch conversations: $e');
      setState(() {
        errorMessage = 'Failed to load conversations. Pull down to retry.';
        isLoading = false;
      });
    }
  }

  Widget _buildListItem(Map<String, dynamic> convo) {
    final avatarUrl = convo['avatar_url'] as String?;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(convo['name'] ?? 'Unknown'),
      subtitle: const Text('Tap to chat'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              receiverId: convo['user_id'],
              receiverName: convo['name'],
              conversationId: convo['conversation_id'],
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: fetchConversations,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : conversations.isEmpty
            ? const Center(child: Text('No conversations yet.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _buildListItem(conversations[index]),
              ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
