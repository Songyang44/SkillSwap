import 'comment.dart';
class Post {
  final String id;
  final String avatarUrl;
  final String username;
  final String contentText;
  final List<String> imageUrls;
  final List<String> skills_i_have;
  final List<String> skills_i_want;
  int likeCount;
  int commentCount;
  final Comment? latestComment;
  final String location;

  Post({
    required this.id,
    required this.avatarUrl,
    required this.username,
    required this.contentText,
    required this.imageUrls,
    required this.skills_i_have,
    required this.skills_i_want,
    this.likeCount = 0,
    this.commentCount = 0,
    this.latestComment,
    this.location = '',
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      avatarUrl: map['avatar_url'] ?? '',
      username: map['username'] ?? 'Anonymous',
      contentText: map['description'] ?? '',
      imageUrls: List<String>.from(map['images'] ?? []),
      skills_i_have: List<String>.from(map['skills_i_have'] ?? []),
      skills_i_want: List<String>.from(map['skills_i_want'] ?? []),
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      latestComment: map['latest_comment'] != null
        ? Comment.fromMap(map['latest_comment']) // ✅ 正确方式
        : null,
      location: map['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar_url': avatarUrl,
      'username': username,
      'description': contentText,
      'images': imageUrls,
      'skills_i_have': skills_i_have,
      'skills_i_want': skills_i_want,
      'like_count': likeCount,
      'comment_count': commentCount,
      'location':location,
    };
  }
}
