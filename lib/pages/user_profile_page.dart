import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../widgets/skill_card.dart';
import 'chat_room_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userInfo;
  List<Skill> skills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final userResponse = await supabase
          .from('user')
          .select()
          .eq('id', widget.userId)
          .single();

      final skillResponse = await supabase
          .from('skills')
          .select()
          .eq('user_id', widget.userId);

      final fetchedSkills = (skillResponse as List)
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        userInfo = userResponse;
        skills = fetchedSkills;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to fetch user info: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 32),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundImage: userInfo?['avatar_url'] != null
                ? NetworkImage(userInfo!['avatar_url'])
                : null,
            backgroundColor: Colors.grey.shade200,
            child: userInfo?['avatar_url'] == null
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userInfo?['name'] ?? 'Anonymous',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          userInfo?['email'] ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userInfo?['location']?.toString().isNotEmpty == true
                  ? userInfo!['location']
                  : '未知',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (skills.isNotEmpty)
          SizedBox(
            height: 240,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 200,
                  child: SkillCard(skill: skills[index]),
                );
              },
            ),
          )
        else
          Center(
            child: Text(
              'No skills added yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSelf = currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('User Profile')),
      body: RefreshIndicator(
        onRefresh: fetchUserInfo,
        child: _buildProfileContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSelf
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You can't chat with yourself")),
                );
              }
            : () async {
                final supabase = Supabase.instance.client;
                final currentUserId = currentUser?.id;
                final receiverId = widget.userId;
                final receiverName = userInfo?['name'] ?? 'User';

                try {
                  final response = await supabase
                      .rpc(
                        'get_or_create_conversation',
                        params: {'user1': currentUserId, 'user2': receiverId},
                      )
                      .single();

                  final conversationId = response['id'] as String?;

                  if (conversationId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to get conversation ID'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        receiverId: receiverId,
                        receiverName: receiverName,
                        conversationId: conversationId,
                      ),
                    ),
                  );
                } catch (e) {
                  print('❌ Error in get_or_create_conversation: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error starting chat: $e')),
                  );
                }
              },
        label: const Text("Let's chat"),
        icon: const Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
