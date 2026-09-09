class ProductModel {
  final int? id;
  final String? nameBn;
  final String? nameEn;
  final String? image;
  final int? brandId;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  ProductModel({
    this.id,
    this.nameBn,
    this.nameEn,
    this.image,
    this.brandId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int?,
      nameBn: json['name_bn'] as String?,
      nameEn: json['name_en'] as String?,
      image: json['image'] as String?,
      brandId: json['brand_id'] as int?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get displayName => nameEn ?? '';
}
