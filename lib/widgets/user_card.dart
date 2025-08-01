import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../pages/user_profile_page.dart';

class UserPostWidget extends StatefulWidget {
  final String user_id;
  final String avatarUrl;
  final String username;
  final bool isVerified;
  final String contentText;
  final List<String> imageUrls;
  final List<String> skills_i_have;
  final List<String> skills_i_want;
  final int likeCount;
  final int commentCount;
  final VoidCallback onChatPressed;
  final VoidCallback onLikePressed;
  final Future<void> Function(String content) onSubmitComment;
  final Comment? latestComment;
  final String? location;

  const UserPostWidget({
    super.key,
    required this.user_id,
    required this.avatarUrl,
    required this.username,
    this.isVerified = false,
    required this.contentText,
    required this.imageUrls,
    required this.skills_i_have,
    required this.skills_i_want,
    required this.likeCount,
    required this.commentCount,
    required this.onChatPressed,
    required this.onLikePressed,
    required this.onSubmitComment,
    this.location,
    this.latestComment,
  });

  @override
  State<UserPostWidget> createState() => _UserPostWidgetState();
}

class _UserPostWidgetState extends State<UserPostWidget> {
  bool showCommentInput = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfilePage(userId: widget.user_id),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(widget.avatarUrl),
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfilePage(userId: widget.user_id),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (widget.location?.isNotEmpty ?? false)
                                ? widget.location!
                                : 'Unknown location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  widget.contentText,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),

                const SizedBox(height: 12),

                if (widget.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.imageUrls[index],
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What I have: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        children: widget.skills_i_have.map(_buildTag).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What I want: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        children: widget.skills_i_want.map(_buildTag).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (widget.latestComment != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.latestComment!.author}: ${widget.latestComment!.content}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                if (showCommentInput) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isNotEmpty) {
                            await widget.onSubmitComment(text);
                            _commentController.clear();
                            setState(() => showCommentInput = false);
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    onPressed: widget.onLikePressed,
                  ),
                  Text('${widget.likeCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () =>
                        setState(() => showCommentInput = !showCommentInput),
                  ),
                  Text('${widget.commentCount}'),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onChatPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.face, size: 20),
                label: const Text(
                  'Let\'s chat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
