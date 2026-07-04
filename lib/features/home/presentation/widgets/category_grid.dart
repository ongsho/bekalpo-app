// lib/features/home/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/category.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final void Function(Category)? onTap;

  const CategoryGrid({super.key, required this.categories, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        // RepaintBoundary isolates each category icon's repaint/decode work
        return RepaintBoundary(
          child: CategoryItem(
            category: cat,
            onTap: () => onTap?.call(cat),
            primaryColor: theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final Color primaryColor;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = category.image != null && category.image!.isNotEmpty;
    // Icons are rendered at 56x56 logical px — decoding at device pixel
    // ratio keeps memory/CPU cost down instead of decoding full-res JPEGs.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final decodeSize = (56 * dpr).round();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.contain,
                    // Caps decoded bitmap size — avoids decoding a
                    // multi-MB original JPEG just to show a 56px icon.
                    // This is what was blocking the main/raster thread
                    // when many categories rendered at once.
                    memCacheWidth: decodeSize,
                    memCacheHeight: decodeSize,
                    // No fade animation — fewer concurrent animation
                    // ticks while the grid first builds.
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => const SizedBox.shrink(),
                    errorWidget: (context, url, error) => Icon(
                      Icons.category_outlined,
                      color: primaryColor,
                      size: 26,
                    ),
                  )
                : Icon(Icons.category_outlined, color: primaryColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            category.nameEn ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if ((category.postCount ?? 0) > 0)
            Text(
              '${category.postCount} ads',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}
