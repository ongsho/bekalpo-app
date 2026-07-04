import '../models/post.dart';
import '../../features/home/data/models/ad_model.dart';

/// Shared Post helpers used across features (home, post_preview, etc).
/// Keeping these here avoids duplicating location/date logic per screen.
extension PostMapper on Post {
  // ── Location (district → thana fallback chain) ──────────────────────────
  String get location {
    final districts = division?.districts;
    final district = (districts != null && districts.isNotEmpty)
        ? districts.first
        : null;
    final thanas = district?.thanas;
    final thana = (thanas != null && thanas.isNotEmpty) ? thanas.first : null;

    return thana?.nameEn ??
        district?.nameEn ??
        division?.nameEn ??
        'Bangladesh';
  }

  /// Full "Thana, District, Division" string — used by post_preview's
  /// detailed meta row. Falls back to 'Bangladesh' if nothing is set.
  String get fullLocation {
    final districts = division?.districts;
    final district = (districts != null && districts.isNotEmpty)
        ? districts.first
        : null;
    final thanas = district?.thanas;
    final thana = (thanas != null && thanas.isNotEmpty) ? thanas.first : null;

    final parts = [
      thana?.nameEn,
      district?.nameEn,
      division?.nameEn,
    ].where((part) => part != null).join(', ');

    return parts.isNotEmpty ? parts : 'Bangladesh';
  }

  // ── Price (from dynamic fieldValues) ─────────────────────────────────────
  String get price {
    final priceField = fieldValues?.cast<dynamic>().firstWhere(
      (f) => f.fieldSlug == 'price',
      orElse: () => null,
    );
    return priceField?.value?.toString() ?? '0';
  }

  bool get isPriceNegotiable {
    final priceTypeField = fieldValues?.cast<dynamic>().firstWhere(
      (f) => f.fieldSlug == 'price_type',
      orElse: () => null,
    );
    return (priceTypeField?.value ?? '').toString().toLowerCase().contains(
      'negotiable',
    );
  }

  // ── Category path ("Vehicles / Car") ─────────────────────────────────────
  String get categoryPath =>
      '${category?.parent?.nameEn ?? "Vehicles"} / ${category?.nameEn ?? "Car"}';

  // ── "isNew" badge (updated within last 7 days) ───────────────────────────
  bool get isRecentlyUpdated =>
      updatedAt != null &&
      updatedAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)));

  // ── Card model for home/listing grids ────────────────────────────────────
  AdModel toAdModel() {
    return AdModel(
      id: id ?? 0,
      title: title ?? 'No title',
      imageUrl: (images != null && images!.isNotEmpty) ? images!.first : '',
      price: price,
      location: location,
      timeAgo: formattedUpdatedAt,
      category: category?.nameEn ?? 'General',
      isNew: isRecentlyUpdated,
      views: counter?.views ?? 0,
      likes: 0,
      slug: slug ?? '',
    );
  }

  // ── Relative date formatting ─────────────────────────────────────────────
  String get formattedUpdatedAt => _formatDateTime(updatedAt);
  String get formattedCreatedAt => _formatDateTime(createdAt);
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
