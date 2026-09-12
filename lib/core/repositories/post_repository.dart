import '../models/post.dart';
import '../models/search_suggestion.dart';
import '../network/api_client.dart';
import '../network/models/api_response.dart';
import '../network/parsers/response_parser.dart';
import '../network/exceptions/api_exception.dart';

class PostRepository {
  final ApiClient _apiClient;

  PostRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ── Get paginated posts ────────────────────────────────────────────────────────
  Future<ApiListResponse<Post>> getPosts({
    int page = 1,
    int perPage = 10,
    int? thanaId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (thanaId != null) {
        queryParams['thana_id'] = thanaId;
      }

      final response = await _apiClient.get(
        'posts',
        queryParameters: queryParams,
      );

      return ResponseParser.parseList<Post>(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load posts: $e',
        originalError: e,
      );
    }
  }

  // ── Get posts by category ─────────────────────────────────────────────────────
  Future<ApiListResponse<Post>> getPostsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts',
        queryParameters: {
          'category_id': categoryId,
          'page': page,
          'per_page': perPage,
        },
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load posts by category: $e',
        originalError: e,
      );
    }
  }

  // ── Get single post by ID ─────────────────────────────────────────────────────
  Future<ApiResponse<Post>> getPostById(int id) async {
    try {
      final response = await _apiClient.get('posts/$id');

      return ResponseParser.parseSingle(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load post: $e',
        originalError: e,
      );
    }
  }

  // ── Get single post by slug ───────────────────────────────────────────────────
  Future<ApiResponse<Post>> getPostBySlug(String slug) async {
    try {
      final response = await _apiClient.get('posts/slug/$slug');

      return ResponseParser.parseSingle(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load post: $e',
        originalError: e,
      );
    }
  }

  // ── Search posts ───────────────────────────────────────────────────────────────
  Future<ApiListResponse<Post>> searchPosts(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts/search',
        queryParameters: {'q': query, 'page': page, 'per_page': perPage},
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to search posts: $e',
        originalError: e,
      );
    }
  }

  // ── Get featured posts ────────────────────────────────────────────────────────
  Future<ApiListResponse<Post>> getFeaturedPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts/featured',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load featured posts: $e',
        originalError: e,
      );
    }
  }

  // ── Get recommended posts ─────────────────────────────────────────────────────
  Future<ApiListResponse<Post>> getRecommendedPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts/recommended',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load recommended posts: $e',
        originalError: e,
      );
    }
  }

  Future<void> registerClick(int postId) =>
      _apiClient.post('posts/click', data: {'post_id': postId});

  Future<void> addToWishlist(int postId) =>
      _apiClient.post('wishlists/store', data: {'post_id': postId});

  // ── Search suggestions ────────────────────────────────────────────────────────
  Future<List<SearchSuggestion>> getSearchSuggestions(
    String query, {
    int? thanaId,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts/search/suggest',
        queryParameters: {
          'query': query,
          if (thanaId != null) 'thana_id': thanaId,
        },
      );

      if (response.data is Map && response.data['suggests'] is List) {
        return (response.data['suggests'] as List)
            .map(
              (json) => SearchSuggestion.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load search suggestions: $e');
    }
  }

  // ── Advanced search with filters ─────────────────────────────────────────────
  Future<ApiListResponse<Post>> searchWithFilters({
    String search = '',
    String? category,
    String? location,
    String? brand,
    String? model,
    String order = 'desc',
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        'posts/search',
        data: {
          'search': search,
          'category': category ?? '',
          'location': location ?? '',
          'brand': brand ?? '',
          'model': model ?? '',
          'order': order,
          'page': page,
        },
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // ── Get my posts (requires authentication) ───────────────────────────────────
  Future<ApiListResponse<Post>> getMyPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts',
        queryParameters: {
          'my_posts': 'true',
          'page': page,
          'per_page': perPage,
        },
      );

      return ResponseParser.parseList<Post>(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load my posts: $e',
        originalError: e,
      );
    }
  }

  // ── Delete post (move to trash) ───────────────────────────────────────────────
  Future<void> deletePost(int postId) async {
    try {
      await _apiClient.deletePost(postId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to delete post: $e',
        originalError: e,
      );
    }
  }

  // ── Get related posts by category ───────────────────────────────────────────────
  Future<ApiListResponse<Post>> getRelatedPosts({
    required int categoryId,
    int perPage = 8,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts',
        queryParameters: {'category_id': categoryId, 'per_page': perPage},
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load related posts: $e',
        originalError: e,
      );
    }
  }

  // ── Get seller posts by user ───────────────────────────────────────────────────
  Future<ApiListResponse<Post>> getSellerPosts({
    required int userId,
    int perPage = 4,
  }) async {
    try {
      final response = await _apiClient.get(
        'posts',
        queryParameters: {'user_id': userId, 'per_page': perPage},
      );

      return ResponseParser.parseList(
        response.data,
        (json) => Post.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Failed to load seller posts: $e',
        originalError: e,
      );
    }
  }
}
