import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../app/router/app_routes.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import 'shared/section_card.dart';

class RelatedPostsSection extends ConsumerWidget {
  final int? categoryId;
  final String? currentPostSlug;

  const RelatedPostsSection({
    super.key,
    required this.categoryId,
    required this.currentPostSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) return const SizedBox.shrink();

    final relatedPostsAsync = ref.watch(relatedPostsProvider(categoryId!));

    return relatedPostsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (response) {
        // Filter out current post and get up to 8 posts
        final relatedPosts = response.data
            .where((post) => post.slug != currentPostSlug)
            .take(8)
            .toList();

        // Only show if there are at least 2 items
        if (relatedPosts.length < 2) return const SizedBox.shrink();

        // Show only even number of items
        final evenCount = relatedPosts.length.isEven
            ? relatedPosts.length
            : relatedPosts.length - 1;

        final ads = relatedPosts
            .take(evenCount)
            .map((post) => post.toAdModel())
            .toList();

        return SectionCard(
          title: 'Related Posts',
          icon: Icons.recommend_outlined,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              return AdCard(
                ad: ads[index],
                postId: relatedPosts[index].id,
                onTap: () {
                  // Navigate to post preview
                  if (ads[index].slug?.isNotEmpty == true) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.postPreview,
                      arguments: ads[index].slug,
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
