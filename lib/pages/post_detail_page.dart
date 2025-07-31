import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  List<Comment> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: false);

      setState(() {
        comments = (response as List)
            .map((map) => Comment.fromMap(map as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch comments: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.post.username)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.post.contentText,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 16),

          // 图片展示
          if (widget.post.imageUrls.isNotEmpty)
            ...widget.post.imageUrls.map(
              (url) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.network(url),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // 技能标签
          if (widget.post.skills_i_have.isNotEmpty) ...[
            Text('Skills I Have', style: theme.textTheme.titleMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.post.skills_i_have.map((skill) => Chip(label: Text(skill))).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.post.skills_i_want.isNotEmpty) ...[
            Text('Skills I Want', style: theme.textTheme.titleMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.post.skills_i_want.map((skill) => Chip(label: Text(skill))).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 点赞评论数
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              const SizedBox(width: 6),
              Text('${widget.post.likeCount} Likes'),
              const SizedBox(width: 24),
              Icon(Icons.comment, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 6),
              Text('${widget.post.commentCount} Comments'),
            ],
          ),

          const SizedBox(height: 24),

          // 评论标题
          Text('Comments', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (comments.isEmpty)
            const Text('No comments yet.')
          else
            ...comments.map(
              (comment) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
