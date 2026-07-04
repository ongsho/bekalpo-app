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
        return CategoryItem(
          category: cat,
          onTap: () => onTap?.call(cat),
          primaryColor: theme.colorScheme.primary,
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
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CachedNetworkImage(
                      imageUrl: category.image!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.category_outlined,
                        color: primaryColor,
                        size: 26,
                      ),
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
