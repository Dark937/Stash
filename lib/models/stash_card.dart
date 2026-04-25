enum CardType { note, video, link, quote, list }

class StashCard {
  final String id;
  final CardType type;
  final String title;
  final String content; // text, Delta JSON, or URL
  final String? category;
  final DateTime dateAdded;
  DateTime? lastReviewed;
  DateTime? deletedAt; // For the 3-day trash cache
  final bool isDeleted; // Flag for trash
  final bool isPinned;
  final List<String> tags;
  final String? imagePath;

  StashCard({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.category,
    required this.dateAdded,
    this.lastReviewed,
    this.deletedAt,
    this.isDeleted = false,
    this.isPinned = false,
    this.tags = const [],
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'content': content,
      'category': category,
      'dateAdded': dateAdded.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'tags': tags,
      'imagePath': imagePath,
    };
  }

  factory StashCard.fromJson(Map<String, dynamic> json) {
    return StashCard(
      id: json['id'],
      type: CardType.values.firstWhere((e) => e.toString() == json['type']),
      title: json['title'],
      content: json['content'],
      category: json['category'],
      dateAdded: DateTime.parse(json['dateAdded']),
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      imagePath: json['imagePath'],
    );
  }

  StashCard copyWith({
    String? title,
    String? content,
    String? category,
    DateTime? lastReviewed,
    DateTime? deletedAt,
    bool? isDeleted,
    bool? isPinned,
    List<String>? tags,
    String? imagePath,
  }) {
    return StashCard(
      id: id,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      dateAdded: dateAdded,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
