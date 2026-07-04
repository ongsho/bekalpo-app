import 'package:bekalpo/core/models/category.dart';
import 'package:bekalpo/core/models/brand.dart';
import 'package:bekalpo/core/models/brand_model.dart';
import 'package:bekalpo/core/models/user.dart';
import 'package:bekalpo/core/models/division.dart';
import 'package:bekalpo/core/models/post_counter.dart';
import 'package:bekalpo/core/models/field_value.dart';

class Post {
  final int? id;
  final int? userId;
  final String? title;
  final String? slug;
  final String? description;
  final List<String>? images;
  final dynamic fields;
  final int? categoryId;
  final int? brandId;
  final int? modelId;
  final int? thanaId;
  final int? isRecommend;
  final int? isFeatured;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? reviewsCount;
  final int? approvedReviewsCount;
  final int? wishlistsCount;
  final int? wishlistsThisMonthCount;
  final dynamic reviewsAvgRating;
  final dynamic approvedReviewsAvgRating;
  final bool? isWishlisted;
  final Category? category;
  final Brand? brand;
  final BrandModel? model;
  final User? user;
  final Division? division;
  final PostCounter? counter;
  final List<dynamic>? reviews;
  final List<FieldValue>? fieldValues;

  Post({
    this.id,
    this.userId,
    this.title,
    this.slug,
    this.description,
    this.images,
    this.fields,
    this.categoryId,
    this.brandId,
    this.modelId,
    this.thanaId,
    this.isRecommend,
    this.isFeatured,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.reviewsCount,
    this.approvedReviewsCount,
    this.wishlistsCount,
    this.wishlistsThisMonthCount,
    this.reviewsAvgRating,
    this.approvedReviewsAvgRating,
    this.isWishlisted,
    this.category,
    this.brand,
    this.model,
    this.user,
    this.division,
    this.counter,
    this.reviews,
    this.fieldValues,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<String>? _parseImages(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) return [value];
      return null;
    }

    return Post(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      title: json['title'] as String?,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      images: _parseImages(json['image']),
      fields: json['fields'],
      categoryId: json['category_id'] as int?,
      brandId: json['brand_id'] as int?,
      modelId: json['model_id'] as int?,
      thanaId: json['thana_id'] as int?,
      isRecommend: json['is_recommend'] as int?,
      isFeatured: json['is_featured'] as int?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      reviewsCount: json['reviews_count'] as int?,
      approvedReviewsCount: json['approved_reviews_count'] as int?,
      wishlistsCount: json['wishlists_count'] as int?,
      wishlistsThisMonthCount: json['wishlists_this_month_count'] as int?,
      reviewsAvgRating: json['reviews_avg_rating'],
      approvedReviewsAvgRating: json['approved_reviews_avg_rating'],
      isWishlisted: json['is_wishlisted'] as bool?,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      brand: json['brand'] != null ? Brand.fromJson(json['brand']) : null,
      model: json['model'] != null ? BrandModel.fromJson(json['model']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      division: json['division'] != null
          ? Division.fromJson(json['division'])
          : null,
      counter: json['counter'] != null
          ? PostCounter.fromJson(json['counter'])
          : null,
      reviews: json['reviews'] as List<dynamic>?,
      fieldValues: json['field_values'] != null
          ? (json['field_values'] as List)
                .map((e) => FieldValue.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'slug': slug,
      'description': description,
      'image': images,
      'fields': fields,
      'category_id': categoryId,
      'brand_id': brandId,
      'model_id': modelId,
      'thana_id': thanaId,
      'is_recommend': isRecommend,
      'is_featured': isFeatured,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reviews_count': reviewsCount,
      'approved_reviews_count': approvedReviewsCount,
      'wishlists_count': wishlistsCount,
      'wishlists_this_month_count': wishlistsThisMonthCount,
      'reviews_avg_rating': reviewsAvgRating,
      'approved_reviews_avg_rating': approvedReviewsAvgRating,
      'is_wishlisted': isWishlisted,
      'category': category?.toJson(),
      'brand': brand?.toJson(),
      'model': model?.toJson(),
      'user': user?.toJson(),
      'division': division?.toJson(),
      'counter': counter?.toJson(),
      'reviews': reviews,
      'field_values': fieldValues?.map((e) => e.toJson()).toList(),
    };
  }
}
