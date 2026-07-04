import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/post_provider.dart';
import 'post_stats_row.dart';
import 'shared/section_card.dart';

/// Price card: category/badge row, price + negotiable label, stats row,
/// and the share / save / rate action row.
///
/// Watches [wishlistedProvider] itself so the parent screen doesn't need
/// to thread wishlist state through — it only needs to know how to
/// perform the toggle (passed in as [onToggleWishlist]).
class PostPriceCard extends ConsumerWidget {
  final int? postId;
  final String categoryPath;
  final String price;
  final bool negotiable;
  final int? views;
  final int? clicks;
  final double? rating;
  final Future<void> Function() onToggleWishlist;

  const PostPriceCard({
    super.key,
    required this.postId,
    required this.categoryPath,
    required this.price,
    required this.negotiable,
    required this.views,
    required this.clicks,
    required this.rating,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = postId != null
        ? ref.watch(wishlistedProvider(postId!))
        : false;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BadgeChip(
                text: 'For sale',
                background: AppColors.warning500,
                foreground: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryPath,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Price: ',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '৳ $price',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand500,
                ),
              ),
              if (negotiable) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '(Negotiable)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          PostStatsRow(views: views, clicks: clicks, rating: rating),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionTextButton(
                icon: Icons.ios_share_outlined,
                label: 'Share',
                onTap: () {},
              ),
              _ActionTextButton(
                icon: wishlisted ? Icons.favorite : Icons.favorite_border,
                label: 'Save',
                color: wishlisted ? Colors.red : null,
                onTap: onToggleWishlist,
              ),
              _ActionTextButton(
                icon: Icons.star_border_rounded,
                label: 'Rate',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTextButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
