// lib/core/models/category.dart
class Category {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final String? slug;
  final String? image;
  final int? parentId;
  final int? categoryId;
  final int? serial;
  final String? status;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? postCount;
  final Category? parent;
  final List<Category>? children;

  Category({
    this.id,
    this.nameEn,
    this.nameBn,
    this.slug,
    this.image,
    this.parentId,
    this.categoryId,
    this.serial,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.postCount,
    this.parent,
    this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      slug: json['slug'] as String?,
      image: json['image'] as String?,
      parentId: json['parent_id'] as int?,
      categoryId: json['category_id'] as int?,
      serial: json['serial'] as int?,
      status: json['status'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      postCount: json['post_count'] as int?,
      parent: json['parent'] != null ? Category.fromJson(json['parent']) : null,
      children: json['children'] != null
          ? (json['children'] as List).map((e) => Category.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
      'slug': slug,
      'image': image,
      'parent_id': parentId,
      'category_id': categoryId,
      'serial': serial,
      'status': status,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'post_count': postCount,
      'parent': parent?.toJson(),
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }
}
