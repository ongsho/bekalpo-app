import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/post.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../widgets/post_gallery.dart';
import '../widgets/post_price_card.dart';
import '../widgets/post_safety_tips.dart';
import '../widgets/post_seller_card.dart';
import '../widgets/post_specification.dart';
import '../widgets/post_title_meta.dart';
import '../widgets/shared/section_card.dart';

class PostPreviewScreen extends ConsumerWidget {
  final String slug;

  const PostPreviewScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postBySlugProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''),
        actions: [
          postAsync.maybeWhen(
            data: (post) {
              final postId = post.id;
              final wishlisted = postId != null
                  ? ref.watch(wishlistedProvider(postId))
                  : false;
              return IconButton(
                icon: Icon(
                  wishlisted ? Icons.favorite : Icons.favorite_border,
                  color: wishlisted ? Colors.red : Colors.black87,
                ),
                onPressed: () => _toggleWishlist(context, ref, post),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error),
        data: (post) => _buildContent(context, ref, post),
      ),
    );
  }

  Future<void> _toggleWishlist(
    BuildContext context,
    WidgetRef ref,
    Post post,
  ) async {
    final postId = post.id;
    if (postId == null) return;
    if (ref.read(wishlistBusyProvider(postId))) return;

    ref.read(wishlistBusyProvider(postId).notifier).state = true;
    final current = ref.read(wishlistedProvider(postId));
    try {
      await ref.read(postRepositoryProvider).addToWishlist(postId);
      ref.read(wishlistedProvider(postId).notifier).state = !current;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update wishlist, try again')),
        );
      }
    } finally {
      ref.read(wishlistBusyProvider(postId).notifier).state = false;
    }
  }

  void _showFullscreenImageView(BuildContext context, List<String> images) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenImageViewer(images: images),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    String errorMessage = 'Failed to load post';
    if (error is ApiException) errorMessage = error.message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(postBySlugProvider(slug)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Post post) {
    final images = post.images ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostTitleMeta(
            title: post.title ?? 'No title',
            createdAt: post.createdAt,
            location: post.fullLocation,
          ),

          const SizedBox(height: 8),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: PostGallery(
              images: images,
              onFullscreenTap: () => _showFullscreenImageView(context, images),
            ),
          ),

          const SizedBox(height: 8),

          PostPriceCard(
            postId: post.id,
            categoryPath: post.categoryPath,
            price: post.price,
            negotiable: post.isPriceNegotiable,
            views: post.counter?.views,
            clicks: post.counter?.clicks,
            rating: post.approvedReviewsAvgRating,
            onToggleWishlist: () => _toggleWishlist(context, ref, post),
          ),

          const SizedBox(height: 8),

          SectionCard(
            title: 'Specification',
            icon: Icons.list_alt_rounded,
            child: PostSpecification(post: post),
          ),

          const SizedBox(height: 8),

          SectionCard(
            title: 'Description',
            icon: Icons.description_outlined,
            child: Text(
              post.description ?? 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (post.user != null)
            PostSellerCard(
              user: post.user!,
              postTitle: post.title ?? 'No title',
              postSlug: post.slug,
            ),

          const SizedBox(height: 8),

          const PostSafetyTips(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final List<String> images;

  const _FullscreenImageViewer({required this.images});

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          _transformationController.value = _zoomAnimation!.value;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
    print('DEBUG: _handleDoubleTapDown called at ${details.localPosition}');
  }

  void _handleDoubleTap() {
    print('DEBUG: _handleDoubleTap called');
    final position = _doubleTapDetails?.localPosition;
    if (position == null) {
      print('DEBUG: position is null, returning');
      return;
    }

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    print('DEBUG: currentScale = $currentScale');
    Matrix4 endMatrix;

    if (currentScale > 1.0) {
      // zoomed in -> zoom out
      endMatrix = Matrix4.identity();
      print('DEBUG: zooming out');
    } else {
      // zoom in centered on tap position
      const targetScale = 2.5;
      endMatrix = Matrix4.identity()
        ..translate(
          -position.dx * (targetScale - 1),
          -position.dy * (targetScale - 1),
        )
        ..scale(targetScale);
      print('DEBUG: zooming in to $targetScale at position $position');
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animController));
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_index + 1} / ${images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    // Reset zoom when page changes
                    _transformationController.value = Matrix4.identity();
                    print('DEBUG: Page changed to $i, zoom reset');
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onDoubleTapDown: _handleDoubleTapDown,
                      onDoubleTap: _handleDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (images.length > 1) ...[
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.white,
                        iconSize: 48,
                        onPressed: () {
                          if (_index > 0) {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.white,
                        iconSize: 48,
                        onPressed: () {
                          if (_index < images.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (images.length > 1)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final active = index == _index;
                    return GestureDetector(
                      onTap: () {
                        _controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade800),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
