import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/user_card.dart';
import '../app_state.dart';
import '../pages/post_detail_page.dart';
import '../pages/chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userInfo;
  bool isUserInfoLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MyAppState>(context, listen: false).fetchPosts();
    });
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        userInfo = response;
        isUserInfoLoading = false;
      });
    } catch (e) {
      print('❌ Failed to fetch user info or skills: $e');
      setState(() => isUserInfoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final posts = appState.posts;
    final isLoadingPosts = appState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Skill market')),
      body: RefreshIndicator(
        onRefresh: () async {
          await appState.fetchPosts();
          await fetchUserInfo();
        },
        child: isLoadingPosts || isUserInfoLoading
            ? Center(child: CircularProgressIndicator())
            : posts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No posts yet.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  // 不允许私聊自己
                  final isSelf = post.user_id == userInfo?['id'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(post: post),
                          ),
                        );
                      },
                      child: UserPostWidget(
                        user_id:post.user_id,
                        avatarUrl: post.avatarUrl,
                        username: post.username,
                        contentText: post.contentText,
                        imageUrls: List<String>.from(post.imageUrls),
                        skills_i_have: List<String>.from(post.skills_i_have),
                        skills_i_want: List<String>.from(post.skills_i_want),
                        location: post.location,
                        likeCount: post.likeCount,
                        commentCount: post.commentCount,
                        onLikePressed: () => appState.likePost(post.id),
                        onSubmitComment: (content) =>
                            appState.commentPost(post.id, content),
                        latestComment: post.latestComment,

                        onChatPressed: isSelf
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "You can't chat with yourself",
                                    ),
                                  ),
                                );
                              }
                            : () async {
                                final supabase = Supabase.instance.client;
                                final currentUserId =
                                    supabase.auth.currentUser!.id;
                                final receiverId = post.user_id;
                                final receiverName = post.username;

                                try {
                                  final response = await supabase
                                      .rpc(
                                        'get_or_create_conversation',
                                        params: {
                                          'user1': currentUserId,
                                          'user2': receiverId,
                                        },
                                      )
                                      .single();

                                  final conversationId =
                                      response['id'] as String?;

                                  if (conversationId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to get conversation ID',
                                        ),
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
                                  print(
                                    '❌ Error in get_or_create_conversation: $e',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error starting chat: $e'),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
