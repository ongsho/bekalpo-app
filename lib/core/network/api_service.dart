import 'api_client.dart';
import 'models/api_response.dart';
import 'exceptions/api_exception.dart';

/// Legacy ApiService wrapper for backward compatibility
/// Delegates to the new ApiClient and ResponseParser
/// @deprecated Use ApiClient directly for new code
class ApiService {
  static final ApiClient _client = ApiClient();

  /// Get request - returns raw dynamic data for backward compatibility
  /// @deprecated Use ApiClient.get() and ResponseParser for typed responses
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client.get(endpoint);
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Get request with typed response
  static Future<ApiResponse<T>> getSingle<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get(endpoint);
      return response.data.asSingle(fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Get request with typed list response
  static Future<ApiListResponse<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get(endpoint);
      return response.data.asList(fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Post request
  static Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _client.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Put request
  static Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _client.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Delete request
  static Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _client.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }

  /// Patch request
  static Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _client.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'API request failed: $e',
        originalError: e,
      );
    }
  }
}
