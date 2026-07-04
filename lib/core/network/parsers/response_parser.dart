import '../models/api_response.dart';
import '../exceptions/api_exception.dart';

/// Centralized response parser for normalizing API responses
/// Handles various response structures and converts them to typed responses
class ResponseParser {
  /// Parse a single object response from dynamic data
  /// Handles:
  /// - Direct object (Map<String, dynamic>)
  /// - Wrapped in {data: ...}
  /// - Wrapped in {success, data, message}
  static ApiResponse<T> parseSingle<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response == null) {
        return ApiResponse.error(message: 'No data received');
      }

      Map<String, dynamic> dataMap;

      // Handle different response structures
      if (response is Map<String, dynamic>) {
        // Check if response has standard API wrapper
        if (response.containsKey('data')) {
          // Response structure: {data: {...}, success: bool, message: string}
          final success = response['success'] as bool? ?? true;
          final message = response['message'] as String?;
          final errorCode = response['error_code'] as String?;
          final data = response['data'];

          if (!success) {
            return ApiResponse.error(
              message: message ?? 'Request failed',
              errorCode: errorCode,
            );
          }

          if (data == null) {
            return ApiResponse.success(message: message);
          }

          if (data is Map<String, dynamic>) {
            dataMap = data;
          } else {
            throw ParseException(
              message: 'Invalid data format: expected Map',
              originalError: data,
            );
          }
        } else {
          // Direct object response
          dataMap = response;
        }
      } else {
        throw ParseException(
          message: 'Invalid response format: expected Map',
          originalError: response,
        );
      }

      // Parse the data using fromJson
      final parsedData = fromJson(dataMap);

      return ApiResponse.success(
        data: parsedData,
        message: response['message'] as String?,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParseException(
        message: 'Failed to parse response: $e',
        originalError: e,
      );
    }
  }

  /// Parse a list response from dynamic data
  /// Handles:
  /// - Direct list
  /// - Wrapped in {data: [...]}
  /// - Wrapped in {success, data, message, pagination}
  static ApiListResponse<T> parseList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response == null) {
        return ApiListResponse.error(message: 'No data received');
      }

      List<dynamic> dataList;
      PaginationMeta? pagination;
      String? message;
      bool success = true;
      String? errorCode;

      // Handle different response structures
      if (response is List) {
        // Direct list response
        dataList = response;
      } else if (response is Map<String, dynamic>) {
        // Check if response has standard API wrapper
        success = response['success'] as bool? ?? true;
        message = response['message'] as String?;
        errorCode = response['error_code'] as String?;

        if (!success) {
          return ApiListResponse.error(
            message: message ?? 'Request failed',
            errorCode: errorCode,
          );
        }

        // Extract data
        if (response.containsKey('data')) {
          final data = response['data'];
          if (data is List) {
            dataList = data;
          } else if (data is Map<String, dynamic>) {
            // Handle nested data structure
            if (data.containsKey('data')) {
              final nestedData = data['data'];
              if (nestedData is List) {
                dataList = nestedData;
              } else {
                throw ParseException(
                  message: 'Invalid nested data format',
                  originalError: data,
                );
              }
            } else {
              throw ParseException(
                message:
                    'Invalid data format: expected List or Map with data key',
                originalError: data,
              );
            }
          } else {
            throw ParseException(
              message: 'Invalid data format: expected List',
              originalError: data,
            );
          }
        } else {
          // No data key, treat entire response as data if it's a list
          throw ParseException(
            message: 'Response missing data key',
            originalError: response,
          );
        }

        // Extract pagination metadata if present
        if (response.containsKey('meta') && response['meta'] is Map) {
          try {
            pagination = PaginationMeta.fromJson(
              Map<String, dynamic>.from(response['meta']),
            );
          } catch (e) {
            // Pagination parsing failed, continue without it
            pagination = null;
          }
        } else if (response.containsKey('pagination') &&
            response['pagination'] is Map) {
          try {
            pagination = PaginationMeta.fromJson(
              Map<String, dynamic>.from(response['pagination']),
            );
          } catch (e) {
            // Pagination parsing failed, continue without it
            pagination = null;
          }
        }
      } else {
        throw ParseException(
          message: 'Invalid response format: expected List or Map',
          originalError: response,
        );
      }

      // Parse each item in the list
      final parsedList = <T>[];
      for (final item in dataList) {
        if (item is Map<String, dynamic>) {
          parsedList.add(fromJson(item));
        } else {
          throw ParseException(
            message: 'Invalid item format: expected Map',
            originalError: item,
          );
        }
      }

      return ApiListResponse.success(
        data: parsedList,
        message: message,
        pagination: pagination,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParseException(
        message: 'Failed to parse list response: $e',
        originalError: e,
      );
    }
  }

  /// Normalize dynamic response to List<dynamic>
  /// Helper method for backward compatibility
  static List<dynamic> normalizeToList(dynamic response) {
    if (response is List) {
      return response;
    } else if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data;
      }
    }
    return [];
  }

  /// Normalize dynamic response to Map<String, dynamic>
  /// Helper method for backward compatibility
  static Map<String, dynamic>? normalizeToMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return Map<String, dynamic>.from(response['data']);
      }
      return response;
    }
    return null;
  }
}

/// Extension methods for convenient response parsing
extension ResponseParserExtension on dynamic {
  /// Parse as single object response
  ApiResponse<T> asSingle<T>(T Function(Map<String, dynamic>) fromJson) {
    return ResponseParser.parseSingle(this, fromJson);
  }

  /// Parse as list response
  ApiListResponse<T> asList<T>(T Function(Map<String, dynamic>) fromJson) {
    return ResponseParser.parseList(this, fromJson);
  }

  /// Normalize to list
  List<dynamic> asNormalizedList() {
    return ResponseParser.normalizeToList(this);
  }

  /// Normalize to map
  Map<String, dynamic>? asNormalizedMap() {
    return ResponseParser.normalizeToMap(this);
  }
}
