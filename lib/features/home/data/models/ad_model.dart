class AdModel {
  final int id;
  final String title;
  final String imageUrl;
  final String price;
  final String location;
  final String timeAgo;
  final String category;
  final bool isNew;
  final int views;
  final int likes;
  final String slug;

  const AdModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.location,
    required this.timeAgo,
    required this.category,
    this.isNew = false,
    this.views = 0,
    this.likes = 0,
    required this.slug,
  });
}
