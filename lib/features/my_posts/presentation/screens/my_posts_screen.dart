import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import '../../../home/data/models/ad_model.dart';
import '../../../../app/router/app_routes.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

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
      // Show bottom sheet with options
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Preview'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.postPreview,
                    arguments: ad.slug,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEdit(ad);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(ad);
                },
              ),
            ],
          ),
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
        final post = myPostsState.posts.firstWhere((p) => p.slug == ad.slug);

        // Just pass the postId, let the screen load data from API
        final postId = post.id != null ? post.id.toString() : '';

        Navigator.pushNamed(context, AppRoutes.postAdd, arguments: postId);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
      }
    }
  }

  void _showDeleteConfirmation(AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(ad);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(AdModel ad) async {
    // Get the post data from the provider
    final myPostsState = ref.read(myPostsProvider).valueOrNull;
    if (myPostsState != null) {
      try {
        final post = myPostsState.posts.firstWhere((p) => p.slug == ad.slug);

        if (post.id != null) {
          try {
            await ref.read(myPostsProvider.notifier).deletePost(post.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete post: $e')),
              );
            }
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPostsAsync = ref.watch(myPostsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        title: const Text('My Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.brand500,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      postId: myPostsState.posts[index].id,
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
