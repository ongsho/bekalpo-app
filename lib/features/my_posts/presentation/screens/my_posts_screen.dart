import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import '../../../home/data/models/ad_model.dart';
import '../../../../app/router/app_routes.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  late final ScrollController _scrollController;
  bool _isLoadMoreTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Load my posts when screen initializes
    Future.microtask(() => ref.read(myPostsProvider.notifier).loadMyPosts());
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (_isLoadMoreTriggered) return;

      final state = ref.read(myPostsProvider).valueOrNull;
      if (state != null && (state.isLoadingMore || !state.hasMore)) return;

      _isLoadMoreTriggered = true;
      ref.read(myPostsProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreTriggered = false;
        } else {
          _isLoadMoreTriggered = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onAdTap(AdModel ad) {
    if (ad.slug?.isNotEmpty == true) {
      // Show a dialog to choose between preview and edit
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Action'),
          content: const Text('What would you like to do with this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.postPreview, arguments: ad.slug);
              },
              child: const Text('Preview'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEdit(ad);
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This ad is unavailable right now')),
      );
    }
  }

  void _navigateToEdit(AdModel ad) {
    // Get the post data from the provider
    final myPostsState = ref.read(myPostsProvider).valueOrNull;
    if (myPostsState != null) {
      try {
        final post = myPostsState.posts.firstWhere(
          (p) => p.slug == ad.slug,
        );
        
        // Prepare initial data for editing
        final Map<String, dynamic> fieldValuesMap = {};
        if (post.fieldValues != null) {
          for (var fv in post.fieldValues!) {
            if (fv.fieldSlug != null) {
              fieldValuesMap[fv.fieldSlug!] = fv.value;
            }
          }
        }
        
        final initialData = {
          'postId': post.id != null ? post.id.toString() : '',
          'category_id': post.categoryId,
          'category_name': post.category?.nameEn,
          'thana_id': post.thanaId,
          'brand_id': post.brandId,
          'brand_name': post.brand?.nameEn,
          'model_id': post.modelId,
          'model_name': post.model?.nameEn,
          'images': post.images,
          'field_values': fieldValuesMap,
        };
        
        Navigator.pushNamed(
          context,
          AppRoutes.postAdd,
          arguments: initialData,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPostsAsync = ref.watch(myPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: myPostsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Failed to load posts',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(myPostsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (myPostsState) {
          if (myPostsState.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first post to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final ads = myPostsState.posts
              .map((post) => post.toAdModel())
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(myPostsProvider.notifier).refresh(),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: ads.length + (myPostsState.isLoadingMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index < ads.length) {
                  return RepaintBoundary(
                    child: AdCard(
                      ad: ads[index],
                      onTap: () => _onAdTap(ads[index]),
                    ),
                  );
                } else {
                  // Loading indicator for load more
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
    );
  }
}
