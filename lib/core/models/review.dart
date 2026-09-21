import 'user.dart';

class Review {
  final int? id;
  final int? postId;
  final int? userId;
  final int? rating;
  final String? comment;
  final bool? approved;
  final bool? visible;
  final int? replyTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  Review({
    this.id,
    this.postId,
    this.userId,
    this.rating,
    this.comment,
    this.approved,
    this.visible,
    this.replyTo,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int?,
      postId: json['post_id'] as int?,
      userId: json['user_id'] as int?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      approved: json['approved'] as bool?,
      visible: json['visible'] as bool?,
      replyTo: json['reply_to'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      user: json['user'] != null && json['user'] is Map
          ? User.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'approved': approved,
      'visible': visible,
      'reply_to': replyTo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
