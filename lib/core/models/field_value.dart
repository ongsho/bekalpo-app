import 'package:bekalpo/core/models/field_item.dart';

class FieldValue {
  final int? id;
  final int? postId;
  final int? fieldId;
  final String? fieldSlug;
  final String? value;
  final List<dynamic>? valueIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? title;
  final List<FieldItem>? items;

  FieldValue({
    this.id,
    this.postId,
    this.fieldId,
    this.fieldSlug,
    this.value,
    this.valueIds,
    this.createdAt,
    this.updatedAt,
    this.title,
    this.items,
  });

  factory FieldValue.fromJson(Map<String, dynamic> json) {
    return FieldValue(
      id: json['id'] as int?,
      postId: json['post_id'] as int?,
      fieldId: json['field_id'] as int?,
      fieldSlug: json['field_slug'] as String?,
      value: json['value'] as String?,
      valueIds: json['value_ids'] as List<dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      title: json['title'] as String?,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => FieldItem.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'field_id': fieldId,
      'field_slug': fieldSlug,
      'value': value,
      'value_ids': valueIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'title': title,
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }
}
