/// Generic API response wrapper for single object responses
/// Provides consistent structure for all API responses
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final String? errorCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errorCode,
  });

  /// Create a success response
  factory ApiResponse.success({
    T? data,
    String? message,
    int statusCode = 200,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Create an error response
  factory ApiResponse.error({
    required String message,
    int? statusCode,
    String? errorCode,
    T? data,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      data: data,
    );
  }

  /// Check if response is successful
  bool get isSuccess => success;

  /// Check if response has data
  bool get hasData => data != null;

  /// Map the data to a different type
  ApiResponse<R> mapData<R>(R Function(T data) mapper) {
    return ApiResponse(
      success: success,
      message: message,
      data: data != null ? mapper(data as T) : null,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode, errorCode: $errorCode)';
  }
}

/// Pagination metadata for list responses
class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int? total;
  final int? lastPage;
  final int? from;
  final int? to;

  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    this.total,
    this.lastPage,
    this.from,
    this.to,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? json['limit'] as int? ?? 10,
      total: json['total'] as int?,
      lastPage: json['last_page'] as int?,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      if (total != null) 'total': total,
      if (lastPage != null) 'last_page': lastPage,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }

  /// Check if there's a next page
  bool get hasNextPage => lastPage == null || currentPage < lastPage!;

  /// Check if there's a previous page
  bool get hasPreviousPage => currentPage > 1;

  @override
  String toString() {
    return 'PaginationMeta(currentPage: $currentPage, perPage: $perPage, total: $total, lastPage: $lastPage)';
  }
}

/// Generic API response wrapper for list responses with pagination
class ApiListResponse<T> {
  final bool success;
  final String? message;
  final List<T> data;
  final PaginationMeta? pagination;
  final int? statusCode;
  final String? errorCode;

  const ApiListResponse({
    required this.success,
    this.message,
    required this.data,
    this.pagination,
    this.statusCode,
    this.errorCode,
  });

  /// Create a success response with list data
  factory ApiListResponse.success({
    required List<T> data,
    String? message,
    PaginationMeta? pagination,
    int statusCode = 200,
  }) {
    return ApiListResponse(
      success: true,
      data: data,
      message: message,
      pagination: pagination,
      statusCode: statusCode,
    );
  }

  /// Create an error response
  factory ApiListResponse.error({
    required String message,
    int? statusCode,
    String? errorCode,
    List<T> data = const [],
  }) {
    return ApiListResponse(
      success: false,
      message: message,
      data: data,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  /// Check if response is successful
  bool get isSuccess => success;

  /// Check if response has data
  bool get hasData => data.isNotEmpty;

  /// Check if response has pagination
  bool get hasPagination => pagination != null;

  /// Get the count of items
  int get count => data.length;

  /// Map the data list to a different type
  ApiListResponse<R> mapData<R>(R Function(T data) mapper) {
    return ApiListResponse(
      success: success,
      message: message,
      data: data.map(mapper).toList(),
      pagination: pagination,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'ApiListResponse(success: $success, count: ${data.length}, pagination: $pagination, statusCode: $statusCode)';
  }
}
