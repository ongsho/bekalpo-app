class SearchSuggestion {
  final String type;
  final String text;
  final String? slug;
  final String? categorySlug;
  final String? location;
  final String? image;
  final String? description;
  final int? categoryId;
  final int? thanaId;
  final String? status;
  final String? query;

  SearchSuggestion({
    required this.type,
    required this.text,
    this.slug,
    this.categorySlug,
    this.location,
    this.image,
    this.description,
    this.categoryId,
    this.thanaId,
    this.status,
    this.query,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      type: json['type'] as String? ?? '',
      text: json['text'] as String? ?? '',
      slug: json['slug'] as String?,
      categorySlug: json['category_slug'] as String?,
      location: json['location'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as int?,
      thanaId: json['thana_id'] as int?,
      status: json['status'] as String?,
      query: json['query'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'slug': slug,
      'category_slug': categorySlug,
      'location': location,
      'image': image,
      'description': description,
      'category_id': categoryId,
      'thana_id': thanaId,
      'status': status,
      'query': query,
    };
  }
}
