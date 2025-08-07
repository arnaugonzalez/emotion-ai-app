/// Centralized Error Handling with Retry Strategies
///
/// Provides consistent error handling across the app with intelligent
/// retry strategies, user-friendly error messages, and automatic fallback.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'circuit_breaker.dart';

final logger = Logger();

enum ErrorSeverity { low, medium, high, critical }

enum RetryStrategy { none, immediate, exponentialBackoff, linearBackoff }

class AppError {
  final String id;
  final String message;
  final String userMessage;
  final ErrorSeverity severity;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  AppError({
    String? id,
    required this.message,
    required this.userMessage,
    required this.severity,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
    this.context = const {},
  }) : id = id ?? _generateErrorId(),
       timestamp = timestamp ?? DateTime.now();

  static String _generateErrorId() {
    return 'error_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'userMessage': userMessage,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

class RetryConfig {
  final RetryStrategy strategy;
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final List<Type> retryableExceptions;

  const RetryConfig({
    this.strategy = RetryStrategy.exponentialBackoff,
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.backoffMultiplier = 2.0,
    this.retryableExceptions = const [
      SocketException,
      TimeoutException,
      HttpException,
    ],
  });
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();

  Stream<AppError> get errorStream => _errorController.stream;
  final List<AppError> _recentErrors = [];
  final int _maxRecentErrors = 50;

  /// Handle an error with automatic classification and retry logic
  Future<T?> handleError<T>({
    required dynamic error,
    StackTrace? stackTrace,
    required String operation,
    Map<String, dynamic> context = const {},
    Future<T> Function()? retryOperation,
    RetryConfig? retryConfig,
    bool showToUser = true,
  }) async {
    final appError = _classifyError(
      error: error,
      stackTrace: stackTrace,
      operation: operation,
      context: context,
    );

    // Log the error
    _logError(appError);

    // Add to recent errors
    _addToRecentErrors(appError);

    // Emit error to stream
    _errorController.add(appError);

    // Attempt retry if configured
    if (retryOperation != null) {
      final result = await _attemptRetry<T>(
        operation: retryOperation,
        config: retryConfig ?? const RetryConfig(),
        originalError: appError,
      );

      if (result != null) {
        return result;
      }
    }

    // Show to user if requested
    if (showToUser) {
      _notifyUser(appError);
    }

    return null;
  }

  /// Classify error and create AppError
  AppError _classifyError({
    required dynamic error,
    StackTrace? stackTrace,
    required String operation,
    Map<String, dynamic> context = const {},
  }) {
    String message;
    String userMessage;
    ErrorSeverity severity;

    if (error is SocketException) {
      message = 'Network connection failed: ${error.message}';
      userMessage = 'Please check your internet connection and try again';
      severity = ErrorSeverity.medium;
    } else if (error is TimeoutException) {
      message = 'Operation timed out: $operation';
      userMessage =
          'The operation is taking longer than expected. Please try again';
      severity = ErrorSeverity.medium;
    } else if (error is HttpException) {
      message = 'HTTP error: ${error.message}';
      userMessage = 'Server communication error. Please try again later';
      severity = ErrorSeverity.medium;
    } else if (error is CircuitBreakerException) {
      message = 'Circuit breaker: ${error.message}';
      userMessage = 'Service temporarily unavailable. Working offline';
      severity = ErrorSeverity.low;
    } else if (error is FormatException) {
      message = 'Data format error: ${error.message}';
      userMessage = 'Invalid data received. Please try again';
      severity = ErrorSeverity.high;
    } else if (error is StateError) {
      message = 'State error: ${error.message}';
      userMessage = 'App state inconsistency detected. Please restart the app';
      severity = ErrorSeverity.critical;
    } else {
      message = 'Unexpected error in $operation: ${error.toString()}';
      userMessage = 'An unexpected error occurred. Please try again';
      severity = ErrorSeverity.high;
    }

    return AppError(
      message: message,
      userMessage: userMessage,
      severity: severity,
      originalError: error,
      stackTrace: stackTrace,
      context: {'operation': operation, ...context},
    );
  }

  /// Attempt retry with configured strategy
  Future<T?> _attemptRetry<T>({
    required Future<T> Function() operation,
    required RetryConfig config,
    required AppError originalError,
  }) async {
    if (config.strategy == RetryStrategy.none) {
      return null;
    }

    // Check if error is retryable
    final isRetryable = config.retryableExceptions.any(
      (type) => originalError.originalError.runtimeType == type,
    );

    if (!isRetryable) {
      logger.w(
        'Error not retryable: ${originalError.originalError.runtimeType}',
      );
      return null;
    }

    for (int attempt = 1; attempt < config.maxAttempts; attempt++) {
      try {
        final delay = _calculateDelay(config, attempt);
        logger.i(
          'Retrying operation, attempt $attempt after ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);
        final result = await operation();

        logger.i('Retry successful on attempt $attempt');
        return result;
      } catch (e) {
        logger.w('Retry attempt $attempt failed: $e');

        if (attempt == config.maxAttempts - 1) {
          logger.e('All retry attempts exhausted');
        }
      }
    }

    return null;
  }

  /// Calculate delay based on retry strategy
  Duration _calculateDelay(RetryConfig config, int attempt) {
    switch (config.strategy) {
      case RetryStrategy.immediate:
        return Duration.zero;

      case RetryStrategy.linearBackoff:
        final delay = Duration(
          milliseconds: config.initialDelay.inMilliseconds * attempt,
        );
        return delay.compareTo(config.maxDelay) > 0 ? config.maxDelay : delay;

      case RetryStrategy.exponentialBackoff:
        final delay = Duration(
          milliseconds:
              (config.initialDelay.inMilliseconds *
                      (config.backoffMultiplier * attempt))
                  .round(),
        );
        return delay.compareTo(config.maxDelay) > 0 ? config.maxDelay : delay;

      case RetryStrategy.none:
        return Duration.zero;
    }
  }

  /// Log error based on severity
  void _logError(AppError error) {
    switch (error.severity) {
      case ErrorSeverity.low:
        logger.d('${error.message} [${error.id}]');
        break;
      case ErrorSeverity.medium:
        logger.w('${error.message} [${error.id}]');
        break;
      case ErrorSeverity.high:
        logger.e('${error.message} [${error.id}]');
        break;
      case ErrorSeverity.critical:
        logger.f(
          '${error.message} [${error.id}]',
          error: error.originalError,
          stackTrace: error.stackTrace,
        );
        break;
    }
  }

  /// Add error to recent errors list
  void _addToRecentErrors(AppError error) {
    _recentErrors.insert(0, error);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeLast();
    }
  }

  /// Notify user of error (placeholder - would integrate with your notification system)
  void _notifyUser(AppError error) {
    // This would integrate with your app's snackbar/toast system
    logger.i('User notification: ${error.userMessage}');
  }

  /// Get recent errors
  List<AppError> getRecentErrors({int? limit}) {
    if (limit != null) {
      return _recentErrors.take(limit).toList();
    }
    return List.from(_recentErrors);
  }

  /// Clear recent errors
  void clearRecentErrors() {
    _recentErrors.clear();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final severityCounts = <ErrorSeverity, int>{};
    for (final error in _recentErrors) {
      severityCounts[error.severity] =
          (severityCounts[error.severity] ?? 0) + 1;
    }

    return {
      'totalErrors': _recentErrors.length,
      'severityBreakdown': severityCounts.map(
        (severity, count) => MapEntry(severity.name, count),
      ),
      'mostRecentError':
          _recentErrors.isNotEmpty
              ? _recentErrors.first.timestamp.toIso8601String()
              : null,
    };
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}

/// Extension for easier error handling
extension ErrorHandlingExtension on Future Function() {
  Future<T?> handleErrors<T>({
    required String operation,
    Map<String, dynamic> context = const {},
    RetryConfig? retryConfig,
    bool showToUser = true,
  }) async {
    final errorHandler = ErrorHandler();

    try {
      final result = await this();
      return result as T;
    } catch (error, stackTrace) {
      return await errorHandler.handleError<T>(
        error: error,
        stackTrace: stackTrace,
        operation: operation,
        context: context,
        retryOperation: this as Future<T> Function(),
        retryConfig: retryConfig,
        showToUser: showToUser,
      );
    }
  }
}

/// Error boundary widget for handling widget build errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, AppError error)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!);
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _error = null;
    }
  }
}
