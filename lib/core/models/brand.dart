import 'package:bekalpo/core/models/category.dart';

class Brand {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final String? image;
  final DateTime? createdAt;
  final List<Category>? categories;

  Brand({
    this.id,
    this.nameEn,
    this.nameBn,
    this.image,
    this.createdAt,
    this.categories,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      image: json['image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      categories: json['categories'] != null
          ? (json['categories'] as List)
                .map((e) => Category.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'categories': categories?.map((e) => e.toJson()).toList(),
    };
  }
}
