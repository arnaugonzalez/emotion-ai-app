/// Custom exceptions for API error handling
library;

/// Base class for all API exceptions
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  /// Get user-friendly error message
  String get userMessage => message;
}

/// 400 Bad Request - Invalid data sent to API
class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.details})
    : super(statusCode: 400);

  @override
  String get userMessage => 'Invalid data provided. Please check your input.';
}

/// 401 Unauthorized - Authentication required or failed
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.details})
    : super(statusCode: 401);

  @override
  String get userMessage => 'Authentication required. Please log in again.';
}

/// 403 Forbidden - User doesn't have permission
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.details})
    : super(statusCode: 403);

  @override
  String get userMessage =>
      'You don\'t have permission to perform this action.';
}

/// 404 Not Found - Resource doesn't exist
class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.details})
    : super(statusCode: 404);

  @override
  String get userMessage => 'The requested resource was not found.';
}

/// 409 Conflict - Resource already exists or conflict with current state
class ConflictException extends ApiException {
  const ConflictException(super.message, {super.details})
    : super(statusCode: 409);

  @override
  String get userMessage =>
      'This item already exists or conflicts with existing data.';
}

/// 422 Unprocessable Entity - Validation errors
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.details})
    : super(statusCode: 422);

  @override
  String get userMessage => 'Data validation failed. Please check your input.';
}

/// 429 Too Many Requests - Rate limiting
class RateLimitException extends ApiException {
  const RateLimitException(super.message, {super.details})
    : super(statusCode: 429);

  @override
  String get userMessage =>
      'Too many requests. Please wait a moment and try again.';
}

/// 500+ Server Error - Internal server issues
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.details});

  @override
  String get userMessage => 'Server error occurred. Please try again later.';
}

/// Network connectivity issues
class NetworkException extends ApiException {
  const NetworkException(super.message) : super(statusCode: null);

  @override
  String get userMessage =>
      'Network connection error. Please check your internet connection.';
}

/// Timeout exceptions
class TimeoutException extends ApiException {
  const TimeoutException(super.message) : super(statusCode: null);

  @override
  String get userMessage => 'Request timed out. Please try again.';
}

/// Unknown/unexpected errors
class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.statusCode, super.details});

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}

/// Factory for creating appropriate exceptions based on HTTP status codes
class ApiExceptionFactory {
  static ApiException fromResponse(
    int statusCode,
    String body, {
    String? defaultMessage,
  }) {
    Map<String, dynamic>? errorData;
    String message = defaultMessage ?? 'Unknown error occurred';

    // Try to parse error response
    try {
      errorData = Map<String, dynamic>.from(
        (body.isNotEmpty)
            ? (body.startsWith('{')
                ? Map<String, dynamic>.from(
                  // Handle both 'detail' and 'message' fields from API
                  (() {
                    final parsed = <String, dynamic>{};
                    if (body.contains('"detail"')) {
                      parsed['detail'] =
                          body
                              .replaceAll(RegExp(r'[{}"]'), '')
                              .split(':')[1]
                              .trim();
                    }
                    if (body.contains('"message"')) {
                      parsed['message'] =
                          body
                              .replaceAll(RegExp(r'[{}"]'), '')
                              .split(':')[1]
                              .trim();
                    }
                    return parsed;
                  })(),
                )
                : {'detail': body})
            : {'detail': 'No error details provided'},
      );

      message = errorData['detail'] ?? errorData['message'] ?? message;
    } catch (e) {
      // If parsing fails, use the raw body or default message
      message = body.isNotEmpty ? body : message;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message, details: errorData);
      case 401:
        return UnauthorizedException(message, details: errorData);
      case 403:
        return ForbiddenException(message, details: errorData);
      case 404:
        return NotFoundException(message, details: errorData);
      case 409:
        return ConflictException(message, details: errorData);
      case 422:
        return ValidationException(message, details: errorData);
      case 429:
        return RateLimitException(message, details: errorData);
      case >= 500:
        return ServerException(
          message,
          statusCode: statusCode,
          details: errorData,
        );
      default:
        return UnknownApiException(
          message,
          statusCode: statusCode,
          details: errorData,
        );
    }
  }

  static ApiException fromException(Object e) {
    if (e is ApiException) return e;

    final message = e.toString();
    if (message.contains('timeout') || message.contains('TimeoutException')) {
      return TimeoutException(message);
    }
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('SocketException')) {
      return NetworkException(message);
    }

    return UnknownApiException(message);
  }
}
