// comment.dart
class Comment {
  final String id;
  final String content;
  final String author;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      content: map['content'] ?? '',
      author: map['author'] ?? 'Anonymous',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
