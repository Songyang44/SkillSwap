import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/post.dart';  // 导入统一 Post 模型

class MyAppState extends ChangeNotifier {
  final client = Supabase.instance.client;

  List<Post> posts = [];
  bool isLoading = false;

  Future<void> fetchPosts() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await client.from('posts').select().order('created_at', ascending: false);

      posts = (response as List).map((map) => Post.fromMap(map)).toList();
    } catch (e) {
      print('Failed to fetch posts: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likePost(String postId) async {
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    posts[postIndex].likeCount++;
    notifyListeners();

    try {
      await client.from('posts').update({'like_count': posts[postIndex].likeCount}).eq('id', postId);
    } catch (e) {
      print('Failed to update like count: $e');
    }
  }
Future<void> commentPost(String postId, String content) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  try {
    // 插入评论表
    await Supabase.instance.client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });

    // 更新 posts 表中的 comment_count
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      posts[postIndex].commentCount++;
      notifyListeners();

      await Supabase.instance.client
          .from('posts')
          .update({'comment_count': posts[postIndex].commentCount})
          .eq('id', postId);
    }
  } catch (e) {
    print('Failed to post comment: $e');
  }
}
}