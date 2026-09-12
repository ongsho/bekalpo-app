import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../app/router/app_routes.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import 'shared/section_card.dart';

class SellerPostsSection extends ConsumerWidget {
  final int? userId;
  final String? currentPostSlug;

  const SellerPostsSection({
    super.key,
    required this.userId,
    required this.currentPostSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) return const SizedBox.shrink();

    final sellerPostsAsync = ref.watch(sellerPostsProvider(userId!));

    return sellerPostsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (response) {
        // Filter out current post and get up to 4 posts
        final sellerPosts = response.data
            .where((post) => post.slug != currentPostSlug)
            .take(4)
            .toList();

        // Only show if there are at least 2 items
        if (sellerPosts.length < 2) return const SizedBox.shrink();

        // Show only even number of items
        final evenCount = sellerPosts.length.isEven
            ? sellerPosts.length
            : sellerPosts.length - 1;

        final ads = sellerPosts
            .take(evenCount)
            .map((post) => post.toAdModel())
            .toList();

        return SectionCard(
          title: 'More from Seller',
          icon: Icons.person_outline,
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
                postId: sellerPosts[index].id,
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
