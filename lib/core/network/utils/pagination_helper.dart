import '../models/api_response.dart';

/// Pagination helper utility for managing paginated API requests
/// Provides convenient methods for pagination operations
class PaginationHelper {
  /// Calculate total number of pages based on total items and per page
  static int calculateTotalPages(int total, int perPage) {
    if (perPage <= 0) return 0;
    return (total / perPage).ceil();
  }

  /// Calculate offset for database queries
  static int calculateOffset(int page, int perPage) {
    if (page < 1) page = 1;
    return (page - 1) * perPage;
  }

  /// Validate page number
  static int validatePage(int page) {
    return page < 1 ? 1 : page;
  }

  /// Validate per page number
  static int validatePerPage(int perPage, {int max = 100}) {
    if (perPage < 1) return 10;
    if (perPage > max) return max;
    return perPage;
  }

  /// Build query parameters for pagination
  static Map<String, dynamic> buildQueryParams({
    required int page,
    required int perPage,
    Map<String, dynamic>? additionalParams,
  }) {
    return {
      'page': validatePage(page),
      'per_page': validatePerPage(perPage),
      ...?additionalParams,
    };
  }

  /// Check if there's a next page
  static bool hasNextPage(PaginationMeta? pagination) {
    return pagination?.hasNextPage ?? false;
  }

  /// Check if there's a previous page
  static bool hasPreviousPage(PaginationMeta? pagination) {
    return pagination?.hasPreviousPage ?? false;
  }

  /// Get next page number
  static int? getNextPage(PaginationMeta? pagination) {
    if (!hasNextPage(pagination)) return null;
    return (pagination?.currentPage ?? 0) + 1;
  }

  /// Get previous page number
  static int? getPreviousPage(PaginationMeta? pagination) {
    if (!hasPreviousPage(pagination)) return null;
    return (pagination?.currentPage ?? 1) - 1;
  }

  /// Get last page number
  static int? getLastPage(PaginationMeta? pagination) {
    return pagination?.lastPage;
  }

  /// Calculate remaining items
  static int? getRemainingItems(PaginationMeta? pagination) {
    final total = pagination?.total;
    final to = pagination?.to;
    if (total == null || to == null) return null;
    return total - to;
  }
}

/// Pagination state manager for UI components
/// Helps manage pagination state in widgets
class PaginationState<T> {
  final List<T> items;
  final PaginationMeta? pagination;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const PaginationState({
    this.items = const [],
    this.pagination,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// Create initial state
  factory PaginationState.initial() {
    return const PaginationState();
  }

  /// Create loading state
  factory PaginationState.loading() {
    return const PaginationState(isLoading: true);
  }

  /// Create error state
  factory PaginationState.error(String message) {
    return PaginationState(
      hasError: true,
      errorMessage: message,
    );
  }

  /// Create success state with data
  factory PaginationState.success(
    List<T> items,
    PaginationMeta? pagination,
  ) {
    return PaginationState(
      items: items,
      pagination: pagination,
    );
  }

  /// Append items to existing list (for infinite scroll)
  PaginationState<T> appendItems(List<T> newItems, PaginationMeta? newPagination) {
    return PaginationState(
      items: [...items, ...newItems],
      pagination: newPagination,
    );
  }

  /// Check if can load more
  bool get canLoadMore => !isLoading && !hasError && PaginationHelper.hasNextPage(pagination);

  /// Check if is first page
  bool get isFirstPage => pagination?.currentPage == 1;

  /// Check if is last page
  bool get isLastPage => !PaginationHelper.hasNextPage(pagination);

  /// Get current page
  int get currentPage => pagination?.currentPage ?? 1;

  /// Get total items
  int? get totalItems => pagination?.total;

  /// Copy with method
  PaginationState<T> copyWith({
    List<T>? items,
    PaginationMeta? pagination,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return PaginationState(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Pagination request builder
/// Helps build paginated API requests
class PaginationRequest {
  int page;
  int perPage;
  final Map<String, dynamic> additionalParams;

  PaginationRequest({
    this.page = 1,
    this.perPage = 10,
    Map<String, dynamic>? additionalParams,
  }) : additionalParams = additionalParams ?? {};

  /// Build query parameters
  Map<String, dynamic> toQueryParams() {
    return PaginationHelper.buildQueryParams(
      page: page,
      perPage: perPage,
      additionalParams: additionalParams,
    );
  }

  /// Reset to first page
  void reset() {
    page = 1;
  }

  /// Go to next page
  void nextPage() {
    page++;
  }

  /// Go to previous page
  void previousPage() {
    if (page > 1) page--;
  }

  /// Go to specific page
  void goToPage(int newPage) {
    page = PaginationHelper.validatePage(newPage);
  }

  /// Update per page
  void updatePerPage(int newPerPage) {
    perPage = PaginationHelper.validatePerPage(newPerPage);
    page = 1; // Reset to first page when changing per page
  }

  /// Add additional parameter
  void addParam(String key, dynamic value) {
    additionalParams[key] = value;
  }

  /// Remove additional parameter
  void removeParam(String key) {
    additionalParams.remove(key);
  }

  /// Clear all additional parameters
  void clearParams() {
    additionalParams.clear();
  }

  /// Create a copy
  PaginationRequest copyWith({
    int? page,
    int? perPage,
    Map<String, dynamic>? additionalParams,
  }) {
    return PaginationRequest(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      additionalParams: additionalParams ?? Map.from(this.additionalParams),
    );
  }
}
