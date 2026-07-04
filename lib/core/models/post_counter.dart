class PostCounter {
  final int? id;
  final int? postId;
  final int? views;
  final int? clicks;
  final int? wishlists;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostCounter({
    this.id,
    this.postId,
    this.views,
    this.clicks,
    this.wishlists,
    this.createdAt,
    this.updatedAt,
  });

  factory PostCounter.fromJson(Map<String, dynamic> json) {
    return PostCounter(
      id: json['id'] as int?,
      postId: json['post_id'] as int?,
      views: json['views'] as int?,
      clicks: json['clicks'] as int?,
      wishlists: json['wishlists'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'views': views,
      'clicks': clicks,
      'wishlists': wishlists,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
