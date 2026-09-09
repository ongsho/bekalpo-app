class PostField {
  final int id;
  final String title;
  final String slug;
  final String type; // radio | select | checkbox | text
  final String? placeholder;
  final PostFieldPivot pivot;
  final List<FieldItem> items;

  PostField({
    required this.id,
    required this.title,
    required this.slug,
    required this.type,
    this.placeholder,
    required this.pivot,
    required this.items,
  });

  factory PostField.fromJson(Map<String, dynamic> json) {
    return PostField(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      placeholder: json['placeholder'] as String?,
      pivot: PostFieldPivot.fromJson(json['pivot'] as Map<String, dynamic>),
      items: (json['items'] as List?)
              ?.map((e) => FieldItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'type': type,
      'placeholder': placeholder,
      'pivot': pivot.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class PostFieldPivot {
  final int categoryId;
  final int serialNo;
  final int isRequired;

  PostFieldPivot({
    required this.categoryId,
    required this.serialNo,
    required this.isRequired,
  });

  factory PostFieldPivot.fromJson(Map<String, dynamic> json) {
    return PostFieldPivot(
      categoryId: json['category_id'] as int,
      serialNo: json['serial_no'] as int,
      isRequired: json['is_required'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'serial_no': serialNo,
      'is_required': isRequired,
    };
  }

  bool get required => isRequired == 1;
}

class FieldItem {
  final int id;
  final String nameEn;
  final String nameBn;

  FieldItem({
    required this.id,
    required this.nameEn,
    required this.nameBn,
  });

  factory FieldItem.fromJson(Map<String, dynamic> json) {
    return FieldItem(
      id: json['id'] as int,
      nameEn: json['name_en'] as String,
      nameBn: json['name_bn'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
    };
  }
}
