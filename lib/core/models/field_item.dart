class FieldItem {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final int? postFieldId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FieldItem({
    this.id,
    this.nameEn,
    this.nameBn,
    this.postFieldId,
    this.createdAt,
    this.updatedAt,
  });

  factory FieldItem.fromJson(Map<String, dynamic> json) {
    return FieldItem(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      postFieldId: json['post_field_id'] as int?,
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
      'name_en': nameEn,
      'name_bn': nameBn,
      'post_field_id': postFieldId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
