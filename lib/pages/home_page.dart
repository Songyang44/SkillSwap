import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/user_card.dart';
import '../app_state.dart';
import '../pages/post_detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MyAppState>(context, listen: false).fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final posts = appState.posts;
    final isLoading = appState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Skill market')),
      body: RefreshIndicator(
        onRefresh: () => appState.fetchPosts(),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No Post')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
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
                            avatarUrl: post.avatarUrl,
                            username: post.username,
                            contentText: post.contentText,
                            imageUrls: List<String>.from(post.imageUrls),
                            skills_i_have: List<String>.from(post.skills_i_have),
                            skills_i_want: List<String>.from(post.skills_i_want),
                            location:post.location,
                            likeCount: post.likeCount,
                            commentCount: post.commentCount,
                            onLikePressed: () => appState.likePost(post.id),
                            // ✅ 传入评论函数（带评论内容）
                            onSubmitComment: (String content) => appState.commentPost(post.id, content),
                            // ✅ 传入最新评论（如果你从数据库拿到了）
                            latestComment: post.latestComment, // 你需要确保 Post 对象中有这个字段
                            onChatPressed: () {
                              print('Let\'s talk with ${post.username}');
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
