/// Circuit Breaker Pattern Implementation
///
/// Provides intelligent failover for API calls, preventing cascading failures
/// and providing automatic recovery when services become available again.
library;

import 'dart:async';
import 'package:logger/logger.dart';

final logger = Logger();

enum CircuitBreakerState { closed, open, halfOpen }

class CircuitBreakerException implements Exception {
  final String message;
  final CircuitBreakerState state;
  final Duration retryAfter;

  CircuitBreakerException(this.message, this.state, this.retryAfter);

  @override
  String toString() =>
      'CircuitBreakerException: $message (State: $state, Retry after: $retryAfter)';
}

class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration timeout;
  final Duration retryDelay;
  final int successThreshold;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.retryDelay = const Duration(minutes: 1),
    this.successThreshold = 3,
  });
}

class CircuitBreaker<T> {
  final String name;
  final CircuitBreakerConfig config;
  final Future<T> Function() operation;
  final Future<T> Function()? fallback;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextRetryTime;

  CircuitBreaker({
    required this.name,
    required this.operation,
    this.fallback,
    this.config = const CircuitBreakerConfig(),
  });

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
  int get successCount => _successCount;
  DateTime? get nextRetryTime => _nextRetryTime;

  /// Execute the operation with circuit breaker protection
  Future<T> execute() async {
    if (_state == CircuitBreakerState.open) {
      if (_canAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        logger.i('🔄 Circuit breaker [$name] transitioning to half-open');
      } else {
        final retryAfter = _nextRetryTime!.difference(DateTime.now());
        logger.w(
          '⚡ Circuit breaker [$name] is open, retry in ${retryAfter.inSeconds}s',
        );

        if (fallback != null) {
          logger.i('🔄 Using fallback for [$name]');
          return await fallback!();
        }

        throw CircuitBreakerException(
          'Circuit breaker is open',
          _state,
          retryAfter,
        );
      }
    }

    try {
      final result = await operation().timeout(config.timeout);
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure(e);

      // If we have a fallback, use it
      if (fallback != null) {
        logger.i('🔄 Operation failed for [$name], using fallback: $e');
        try {
          return await fallback!();
        } catch (fallbackError) {
          logger.e('❌ Fallback also failed for [$name]: $fallbackError');
          rethrow;
        }
      }

      rethrow;
    }
  }

  /// Check if we can attempt to reset the circuit breaker
  bool _canAttemptReset() {
    if (_nextRetryTime == null) return true;
    return DateTime.now().isAfter(_nextRetryTime!);
  }

  /// Handle successful operation
  void _onSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
    _nextRetryTime = null;

    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      if (_successCount >= config.successThreshold) {
        _state = CircuitBreakerState.closed;
        _successCount = 0;
        logger.i('✅ Circuit breaker [$name] closed after successful recovery');
      }
    } else {
      _state = CircuitBreakerState.closed;
      logger.d('✅ Circuit breaker [$name] operation successful');
    }
  }

  /// Handle failed operation
  void _onFailure(dynamic error) {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    _successCount = 0;

    logger.w(
      '❌ Circuit breaker [$name] failure $_failureCount/${config.failureThreshold}: $error',
    );

    if (_failureCount >= config.failureThreshold) {
      _state = CircuitBreakerState.open;
      _nextRetryTime = DateTime.now().add(config.retryDelay);

      logger.e(
        '⚡ Circuit breaker [$name] opened due to $_failureCount failures. '
        'Next retry: ${_nextRetryTime!.toIso8601String()}',
      );
    }
  }

  /// Reset the circuit breaker manually
  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _nextRetryTime = null;
    logger.i('🔄 Circuit breaker [$name] manually reset');
  }

  /// Get current status information
  Map<String, dynamic> getStatus() {
    return {
      'name': name,
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'nextRetryTime': _nextRetryTime?.toIso8601String(),
      'canRetry': _canAttemptReset(),
    };
  }
}

/// Circuit Breaker Manager for handling multiple circuit breakers
class CircuitBreakerManager {
  static final CircuitBreakerManager _instance =
      CircuitBreakerManager._internal();
  factory CircuitBreakerManager() => _instance;
  CircuitBreakerManager._internal();

  final Map<String, CircuitBreaker> _circuitBreakers = {};

  /// Get or create a circuit breaker for an operation
  CircuitBreaker<T> getCircuitBreaker<T>({
    required String name,
    required Future<T> Function() operation,
    Future<T> Function()? fallback,
    CircuitBreakerConfig? config,
  }) {
    if (_circuitBreakers.containsKey(name)) {
      return _circuitBreakers[name] as CircuitBreaker<T>;
    }

    final circuitBreaker = CircuitBreaker<T>(
      name: name,
      operation: operation,
      fallback: fallback,
      config: config ?? const CircuitBreakerConfig(),
    );

    _circuitBreakers[name] = circuitBreaker;
    return circuitBreaker;
  }

  /// Execute an operation with circuit breaker protection
  Future<T> execute<T>({
    required String name,
    required Future<T> Function() operation,
    Future<T> Function()? fallback,
    CircuitBreakerConfig? config,
  }) async {
    final circuitBreaker = getCircuitBreaker<T>(
      name: name,
      operation: operation,
      fallback: fallback,
      config: config,
    );

    return await circuitBreaker.execute();
  }

  /// Reset a specific circuit breaker
  void resetCircuitBreaker(String name) {
    final circuitBreaker = _circuitBreakers[name];
    if (circuitBreaker != null) {
      circuitBreaker.reset();
    }
  }

  /// Reset all circuit breakers
  void resetAll() {
    for (final circuitBreaker in _circuitBreakers.values) {
      circuitBreaker.reset();
    }
    logger.i('🔄 All circuit breakers reset');
  }

  /// Get status of all circuit breakers
  List<Map<String, dynamic>> getAllStatus() {
    return _circuitBreakers.values.map((cb) => cb.getStatus()).toList();
  }

  /// Get circuit breakers in open state
  List<String> getOpenCircuitBreakers() {
    return _circuitBreakers.entries
        .where((entry) => entry.value.state == CircuitBreakerState.open)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if any circuit breakers are open
  bool hasOpenCircuitBreakers() {
    return _circuitBreakers.values.any(
      (cb) => cb.state == CircuitBreakerState.open,
    );
  }
}

/// Extension to make circuit breaker usage more convenient
extension CircuitBreakerExtension on Future Function() {
  Future<T> withCircuitBreaker<T>({
    required String name,
    Future<T> Function()? fallback,
    CircuitBreakerConfig? config,
  }) async {
    final manager = CircuitBreakerManager();
    return await manager.execute<T>(
      name: name,
      operation: this as Future<T> Function(),
      fallback: fallback,
      config: config,
    );
  }
}
