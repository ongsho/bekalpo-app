class BrandModel {
  final int? id;
  final String? nameBn;
  final String? nameEn;
  final String? image;
  final int? brandId;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  BrandModel({
    this.id,
    this.nameBn,
    this.nameEn,
    this.image,
    this.brandId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as int?,
      nameBn: json['name_bn'] as String?,
      nameEn: json['name_en'] as String?,
      image: json['image'] as String?,
      brandId: json['brand_id'] as int?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_bn': nameBn,
      'name_en': nameEn,
      'image': image,
      'brand_id': brandId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
