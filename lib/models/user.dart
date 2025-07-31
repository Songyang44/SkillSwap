class User {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final String location;
  final List<Skill> skillsToOffer;
  final List<Skill> skillsToLearn;
  final double rating;
  final int reviewCount;
  final bool isOnline;

  User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.location,
    required this.skillsToOffer,
    required this.skillsToLearn,
    required this.rating,
    required this.reviewCount,
    this.isOnline = false,
  });
}

class Skill {
  final String id;
  final String name;
  final String category;
  final String description;
  final String icon;
  final int level;
  final List<String> tags;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.level,
    required this.tags,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      level: json['level'] ?? 1,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
