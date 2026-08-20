import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/exceptions/api_exception.dart';

/// Production-grade HTTP client using Dio with interceptors
/// Handles authentication, logging, error handling, and retries
class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  static const String _baseUrl = 'https://admin.bekalpo.com/api/';
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 30);
  static const String _tokenKey = 'auth_token';

  ApiClient._internal() {
    _dio = Dio(_createBaseOptions());
    _setupInterceptors();
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Create base Dio options
  BaseOptions _createBaseOptions() {
    return BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  /// Setup interceptors for logging, authentication, and error handling
  void _setupInterceptors() {
    // Request interceptor: Add auth token, logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request
          _logRequest(options);

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          _logResponse(response);

          handler.next(response);
        },
        onError: (error, handler) {
          // Log error
          _logError(error);

          // Convert Dio error to ApiException
          final apiException = _handleDioError(error);

          // Retry logic for network errors
          if (apiException is NetworkException &&
              error.requestOptions.extra['_retryCount'] == null) {
            error.requestOptions.extra['_retryCount'] = 0;
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
              message: apiException.message,
            ),
          );
        },
      ),
    );

    // Retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response);

        if (statusCode == null) {
          return BadRequestException(
            message: message ?? 'Request failed',
            statusCode: 400,
            originalError: error,
          );
        }

        switch (statusCode) {
          case 400:
            return BadRequestException(
              message: message ?? 'Bad request',
              statusCode: statusCode,
              originalError: error,
            );
          case 401:
            return UnauthorizedException(
              message: message ?? 'Unauthorized',
              statusCode: statusCode,
              originalError: error,
            );
          case 403:
            return UnauthorizedException(
              message: message ?? 'Forbidden',
              statusCode: statusCode,
              originalError: error,
            );
          case 404:
            return NotFoundException(
              message: message ?? 'Resource not found',
              statusCode: statusCode,
              originalError: error,
            );
          case 422:
            return ValidationException(
              message: message ?? 'Validation failed',
              statusCode: statusCode,
              validationErrors: error.response?.data is Map
                  ? Map<String, dynamic>.from(
                      error.response?.data['errors'] ?? {},
                    )
                  : null,
              originalError: error,
            );
          default:
            if (statusCode >= 500) {
              return ServerException(
                message: message ?? 'Server error',
                statusCode: statusCode,
                originalError: error,
              );
            }
            return BadRequestException(
              message: message ?? 'Request failed',
              statusCode: statusCode,
              originalError: error,
            );
        }

      case DioExceptionType.cancel:
        return const UnknownException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return const NetworkException(message: 'No internet connection');
        }
        return UnknownException(
          message: error.message ?? 'Unknown error occurred',
          originalError: error,
        );

      default:
        return UnknownException(
          message: error.message ?? 'Unknown error occurred',
          originalError: error,
        );
    }
  }

  /// Extract error message from response
  String? _extractErrorMessage(Response? response) {
    if (response?.data == null) return null;

    final data = response!.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['error_description'] as String?;
    }
    return null;
  }

  /// Get stored auth token (implement with secure storage in production)
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print(
        'API Client: Token read from SharedPreferences: ${token != null ? "Found" : "Not found"}',
      );
      return token;
    } catch (e) {
      print('API Client: Error reading token: $e');
      return null;
    }
  }

  /// Set auth token (implement with secure storage in production)
  Future<void> setAuthToken(String? token) async {
    // This method is now handled by AuthNotifier
    // Kept for compatibility if needed elsewhere
  }

  /// Clear auth token
  Future<void> clearAuthToken() async {
    // This method is now handled by AuthNotifier
    // Kept for compatibility if needed elsewhere
  }

  /// Log request details
  void _logRequest(RequestOptions options) {
    // TODO: Implement proper logging (e.g., using logger package)
    // For now, simple print for debugging
    print('API Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      print('Request Data: ${options.data}');
    }
  }

  /// Log response details
  void _logResponse(Response response) {
    // TODO: Implement proper logging (e.g., using logger package)
    print(
      'API Response: ${response.statusCode} ${response.requestOptions.uri}',
    );
    print('Response Data: ${response.data}');
  }

  /// Log error details
  void _logError(DioException error) {
    // TODO: Implement proper logging (e.g., using logger package)
    print('API Error: ${error.type} - ${error.message}');
  }

  // HTTP Methods

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

/// Retry interceptor for Dio
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['_retryCount'] as int? ?? 0;

    // Only retry on network errors and 5xx errors
    final shouldRetry =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        (err.type == DioExceptionType.badResponse &&
            err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);

    if (shouldRetry && retryCount < retries) {
      extra['_retryCount'] = retryCount + 1;

      // Wait before retrying
      final delay = retryDelays[retryCount.clamp(0, retryDelays.length - 1)];
      await Future.delayed(delay);

      // Retry the request
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
