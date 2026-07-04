// lib/core/providers/post_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../network/models/api_response.dart';

// ── Repository ──────────────────────────────────────────────────────────────
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

// ── Disk cache helpers ──────────────────────────────────────────────────────
const _kPostCacheKey = 'cache_posts_all_v1';

Future<List<Post>?> _readPostCache() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_kPostCacheKey);
  if (json == null) return null;
  try {
    final decoded = jsonDecode(json) as List;
    return decoded
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return null;
  }
}

Future<void> _writePostCache(List<Post> posts) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPostCacheKey,
    jsonEncode(posts.map((p) => p.toJson()).toList()),
  );
}

/// Find post by slug from cached posts
Future<Post?> _findPostBySlugInCache(String slug) async {
  final cached = await _readPostCache();
  if (cached == null) return null;
  try {
    return cached.firstWhere((p) => p.slug == slug);
  } catch (_) {
    return null;
  }
}

// ── State ───────────────────────────────────────────────────────────────────
class PostsState {
  final List<Post> posts;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  /// True when showing disk-cached data because the network fetch failed
  final bool isShowingCachedData;

  const PostsState({
    this.posts = const [],
    this.currentPage = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isShowingCachedData = false,
  });

  PostsState copyWith({
    List<Post>? posts,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isShowingCachedData,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isShowingCachedData: isShowingCachedData ?? this.isShowingCachedData,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────
class PostsNotifier extends AsyncNotifier<PostsState> {
  static const int _perPage = 10;

  @override
  Future<PostsState> build() async {
    // Return loading state immediately to avoid blocking first build
    // Then load data in background
    Future.microtask(() async {
      try {
        final result = await _fetchPage(1, existing: []);
        // Cache all posts for offline fallback
        await _writePostCache(result.posts);
        state = AsyncData(result);
      } catch (e) {
        // Network failed — fall back to disk cache
        final cached = await _readPostCache();
        if (cached != null && cached.isNotEmpty) {
          state = AsyncData(
            PostsState(
              posts: cached,
              currentPage: 1,
              hasMore: false,
              isShowingCachedData: true,
            ),
          );
        } else {
          state = AsyncError(e, StackTrace.current);
        }
      }
    });

    // Return initial loading state
    return PostsState(posts: [], currentPage: 1, hasMore: true);
  }

  Future<PostsState> _fetchPage(
    int page, {
    required List<Post> existing,
  }) async {
    final repo = ref.read(postRepositoryProvider);
    final response = await repo.getPosts(page: page, perPage: _perPage);

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Failed to load posts');
    }

    final newPosts = response.data;
    return PostsState(
      posts: [...existing, ...newPosts],
      currentPage: page,
      isLoadingMore: false,
      hasMore: response.pagination?.hasNextPage ?? newPosts.length >= _perPage,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore || !current.hasMore) return;
    if (current.isShowingCachedData) return; // don't paginate stale cache

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(
        current.currentPage + 1,
        existing: current.posts,
      );
      // Update cache with all loaded posts
      await _writePostCache(next.posts);
      state = AsyncData(next);
    } catch (e) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final fresh = await _fetchPage(1, existing: []);
      // Update cache with all loaded posts
      await _writePostCache(fresh.posts);
      state = AsyncData(fresh);
    } catch (e, st) {
      // On refresh failure, fall back to cache rather than error screen
      final cached = await _readPostCache();
      if (cached != null && cached.isNotEmpty) {
        state = AsyncData(
          PostsState(
            posts: cached,
            currentPage: 1,
            hasMore: false,
            isShowingCachedData: true,
          ),
        );
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, PostsState>(() {
  return PostsNotifier();
});

// ── Single post + by-category ───────────────────────────────────────────────
final postsByCategoryProvider =
    FutureProvider.family<ApiListResponse<Post>, int>((ref, categoryId) async {
      final repository = ref.watch(postRepositoryProvider);
      return repository.getPostsByCategory(categoryId);
    });

final postProvider = FutureProvider.family<ApiResponse<Post>, int>((
  ref,
  id,
) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostById(id);
});

final postBySlugProvider = FutureProvider.family<Post, String>((
  ref,
  slug,
) async {
  try {
    final repository = ref.watch(postRepositoryProvider);
    final response = await repository.getPostBySlug(slug);
    final postId = response.data?.id;
    if (postId != null) {
      repository.registerClick(postId).catchError((_) {});
    }
    return response.data!;
  } catch (_) {
    // Network failed - try to find in cache
    final cached = await _findPostBySlugInCache(slug);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

// ── Wishlist ────────────────────────────────────────────────────────────────
final wishlistedProvider = StateProvider.family<bool, int>(
  (ref, postId) => false,
);
final wishlistBusyProvider = StateProvider.family<bool, int>(
  (ref, postId) => false,
);
