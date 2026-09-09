class DraftPost {
  final String postId;
  final Map<String, dynamic> formData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'draft', 'partial', 'completed'

  DraftPost({
    required this.postId,
    required this.formData,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
  });

  factory DraftPost.fromJson(Map<String, dynamic> json) {
    return DraftPost(
      postId: json['post_id'] as String,
      formData: Map<String, dynamic>.from(json['form_data'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'form_data': formData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  DraftPost copyWith({
    String? postId,
    Map<String, dynamic>? formData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return DraftPost(
      postId: postId ?? this.postId,
      formData: formData ?? this.formData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
