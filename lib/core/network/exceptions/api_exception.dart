/// Base exception class for all API-related errors
/// Provides consistent error handling across the application
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message';
}

/// Network-related errors (no internet, connection timeout, etc.)
class NetworkException extends ApiException {
  const NetworkException({
    String message = 'Network error occurred',
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Timeout errors when request takes too long
class TimeoutException extends ApiException {
  const TimeoutException({
    String message = 'Request timeout',
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Server-side errors (5xx status codes)
class ServerException extends ApiException {
  const ServerException({
    String message = 'Server error occurred',
    required int statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Client-side errors (4xx status codes)
class BadRequestException extends ApiException {
  const BadRequestException({
    String message = 'Bad request',
    required int statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Authentication/authorization errors (401, 403)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    String message = 'Unauthorized access',
    required int statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Resource not found (404)
class NotFoundException extends ApiException {
  const NotFoundException({
    String message = 'Resource not found',
    required int statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// JSON parsing errors
class ParseException extends ApiException {
  const ParseException({
    String message = 'Failed to parse response',
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Validation errors (422)
class ValidationException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  const ValidationException({
    String message = 'Validation failed',
    required int statusCode,
    this.validationErrors,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Unknown/unexpected errors
class UnknownException extends ApiException {
  const UnknownException({
    String message = 'An unknown error occurred',
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// Utility class to convert Dio errors to ApiException
class ApiExceptionFactory {
  static ApiException fromError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    // Handle Dio errors if Dio is being used
    if (error.toString().contains('SocketException') ||
        error.toString().contains('No Internet')) {
      return const NetworkException(message: 'No internet connection');
    }

    if (error.toString().contains('TimeoutException')) {
      return const TimeoutException();
    }

    return UnknownException(
      message: error.toString(),
      originalError: error,
    );
  }
}
