class Contact {
  final int? id;
  final int? userId;
  final String? type;
  final String? value;
  final DateTime? verifiedAt;
  final bool? isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    this.id,
    this.userId,
    this.type,
    this.value,
    this.verifiedAt,
    this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      type: json['type'] as String?,
      value: json['value'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      isPrimary: json['is_primary'] as bool?,
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
      'user_id': userId,
      'type': type,
      'value': value,
      'verified_at': verifiedAt?.toIso8601String(),
      'is_primary': isPrimary,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
