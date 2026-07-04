class SearchSuggestion {
  final String type;
  final String text;
  final String? slug;
  final String? categorySlug;
  final String? location;

  SearchSuggestion({
    required this.type,
    required this.text,
    this.slug,
    this.categorySlug,
    this.location,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      type: json['type'] as String? ?? '',
      text: json['text'] as String? ?? '',
      slug: json['slug'] as String?,
      categorySlug: json['category_slug'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'slug': slug,
      'category_slug': categorySlug,
      'location': location,
    };
  }
}
