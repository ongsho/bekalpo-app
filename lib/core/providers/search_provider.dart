// lib/core/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import 'post_provider.dart';

class SearchFilters {
  final String search;
  final String? category;
  final String? location;
  final String? brand;
  final String? model;
  final String order;
  final int page;

  SearchFilters({
    this.search = '',
    this.category,
    this.location,
    this.brand,
    this.model,
    this.order = 'desc',
    this.page = 1,
  });

  SearchFilters copyWith({
    String? search,
    String? category,
    String? location,
    String? brand,
    String? model,
    String? order,
    int? page,
  }) {
    return SearchFilters(
      search: search ?? this.search,
      category: category ?? this.category,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      order: order ?? this.order,
      page: page ?? this.page,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'category': category ?? '',
      'location': location ?? '',
      'brand': brand ?? '',
      'model': model ?? '',
      'order': order,
      'page': page,
    };
  }
}

class SearchState {
  final List<Post> results;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const SearchState({
    this.results = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  SearchState copyWith({
    List<Post>? results,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return SearchState(
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final PostRepository _repository;
  SearchFilters _currentFilters;

  SearchNotifier(this._repository, SearchFilters filters)
    : _currentFilters = filters,
      super(const SearchState());

  Future<void> search(SearchFilters filters) async {
    _currentFilters = filters.copyWith(page: 1);
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.searchWithFilters(
        search: filters.search,
        category: filters.category,
        location: filters.location,
        brand: filters.brand,
        model: filters.model,
        order: filters.order,
        page: filters.page,
      );

      state = state.copyWith(
        results: response.data,
        currentPage: response.pagination?.currentPage ?? 1,
        lastPage: response.pagination?.lastPage ?? 1,
        total: response.pagination?.total ?? 0,
        isLoading: false,
        hasMore: response.pagination?.hasNextPage ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = _currentFilters.page + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repository.searchWithFilters(
        search: _currentFilters.search,
        category: _currentFilters.category,
        location: _currentFilters.location,
        brand: _currentFilters.brand,
        model: _currentFilters.model,
        order: _currentFilters.order,
        page: nextPage,
      );

      _currentFilters = _currentFilters.copyWith(page: nextPage);

      state = state.copyWith(
        results: [...state.results, ...response.data],
        currentPage: response.pagination?.currentPage ?? nextPage,
        lastPage: response.pagination?.lastPage ?? state.lastPage,
        total: response.pagination?.total ?? state.total,
        isLoadingMore: false,
        hasMore: response.pagination?.hasNextPage ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final searchProvider =
    StateNotifierProvider.family<SearchNotifier, SearchState, SearchFilters>((
      ref,
      filters,
    ) {
      final repository = ref.watch(postRepositoryProvider);
      final notifier = SearchNotifier(repository, filters);

      // Auto-search on creation if filters are not empty
      if (filters.search.isNotEmpty ||
          filters.category != null ||
          filters.location != null) {
        Future.microtask(() => notifier.search(filters));
      }

      return notifier;
    });
