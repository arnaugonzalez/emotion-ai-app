/// Enhanced API Service with Circuit Breaker and Error Handling
///
/// Wraps the existing API service with circuit breaker pattern,
/// intelligent retry strategies, and centralized error handling.

import 'dart:async';
import '../../data/api_service.dart';
import '../../data/models/emotional_record.dart';
import '../../data/models/breathing_session.dart';
import '../../data/models/breathing_pattern.dart';
import '../../data/models/custom_emotion.dart';
import '../../data/models/user_limitations.dart';
import '../../data/models/chat_response.dart';
import 'circuit_breaker.dart';
import 'error_handler.dart';
import 'sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class EnhancedApiService {
  final ApiService _apiService;
  final CircuitBreakerManager _circuitBreakerManager;
  final ErrorHandler _errorHandler;
  final SQLiteHelper _sqliteHelper;

  EnhancedApiService({
    ApiService? apiService,
    CircuitBreakerManager? circuitBreakerManager,
    ErrorHandler? errorHandler,
    SQLiteHelper? sqliteHelper,
  }) : _apiService = apiService ?? ApiService(),
       _circuitBreakerManager =
           circuitBreakerManager ?? CircuitBreakerManager(),
       _errorHandler = errorHandler ?? ErrorHandler(),
       _sqliteHelper = sqliteHelper ?? SQLiteHelper();

  /// Circuit breaker configurations for different operations
  static const _defaultConfig = CircuitBreakerConfig(
    failureThreshold: 3,
    timeout: Duration(seconds: 30),
    retryDelay: Duration(minutes: 2),
  );

  static const _fastConfig = CircuitBreakerConfig(
    failureThreshold: 2,
    timeout: Duration(seconds: 10),
    retryDelay: Duration(seconds: 30),
  );

  static const _criticalConfig = CircuitBreakerConfig(
    failureThreshold: 5,
    timeout: Duration(minutes: 1),
    retryDelay: Duration(minutes: 5),
  );

  /// Enhanced login with circuit breaker protection
  Future<dynamic> login(String email, String password) async {
    return await _circuitBreakerManager.execute(
      name: 'auth_login',
      operation: () => _apiService.login(email, password),
      fallback: () async {
        logger.w('Login circuit breaker open, cannot authenticate offline');
        throw Exception('Authentication requires internet connection');
      },
      config: _criticalConfig,
    );
  }

  /// Enhanced user creation with retry
  Future<dynamic> createUser(
    String email,
    String password,
    String firstName,
    String lastName, {
    DateTime? dateOfBirth,
  }) async {
    return await _errorHandler.handleError(
      error: null,
      operation: 'create_user',
      retryOperation:
          () => _circuitBreakerManager.execute(
            name: 'auth_register',
            operation:
                () => _apiService.createUser(
                  email,
                  password,
                  firstName,
                  lastName,
                  dateOfBirth: dateOfBirth,
                ),
            config: _criticalConfig,
          ),
      retryConfig: const RetryConfig(
        strategy: RetryStrategy.exponentialBackoff,
        maxAttempts: 2,
      ),
    );
  }

  /// Enhanced emotional records with offline fallback
  Future<EmotionalRecord?> createEmotionalRecord(EmotionalRecord record) async {
    try {
      return await _circuitBreakerManager.execute<EmotionalRecord>(
        name: 'emotional_records_create',
        operation: () => _apiService.createEmotionalRecord(record),
        fallback: () async {
          // Store locally and queue for sync
          await _sqliteHelper.insertEmotionalRecord(record);
          logger.i('Stored emotional record locally for later sync');
          return record;
        },
        config: _defaultConfig,
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError<EmotionalRecord>(
        error: e,
        stackTrace: stackTrace,
        operation: 'create_emotional_record',
        context: {'record_id': record.id},
        retryOperation: () => _apiService.createEmotionalRecord(record),
        retryConfig: const RetryConfig(maxAttempts: 2),
      );
    }
  }

  /// Enhanced get emotional records with local fallback
  Future<List<EmotionalRecord>> getEmotionalRecords() async {
    try {
      return await _circuitBreakerManager.execute<List<EmotionalRecord>>(
        name: 'emotional_records_get',
        operation: () => _apiService.getEmotionalRecords(),
        fallback: () async {
          // Return local data
          final localRecords = await _sqliteHelper.getAllEmotionalRecords();
          logger.i('Returning ${localRecords.length} local emotional records');
          return localRecords;
        },
        config: _fastConfig,
      );
    } catch (e, stackTrace) {
      final result = await _errorHandler.handleError<List<EmotionalRecord>>(
        error: e,
        stackTrace: stackTrace,
        operation: 'get_emotional_records',
        retryOperation: () => _apiService.getEmotionalRecords(),
        retryConfig: const RetryConfig(maxAttempts: 2),
        showToUser: false, // Don't show error for data fetching
      );

      // Always return local data as fallback
      if (result == null) {
        final localRecords = await _sqliteHelper.getAllEmotionalRecords();
        logger.i(
          'Fallback: returning ${localRecords.length} local emotional records',
        );
        return localRecords;
      }

      return result;
    }
  }

  /// Enhanced breathing session creation
  Future<BreathingSessionData?> createBreathingSession(
    BreathingSessionData session,
  ) async {
    try {
      return await _circuitBreakerManager.execute<BreathingSessionData>(
        name: 'breathing_sessions_create',
        operation: () => _apiService.createBreathingSession(session),
        fallback: () async {
          await _sqliteHelper.insertBreathingSession(session);
          logger.i('Stored breathing session locally for later sync');
          return session;
        },
        config: _defaultConfig,
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError<BreathingSessionData>(
        error: e,
        stackTrace: stackTrace,
        operation: 'create_breathing_session',
        context: {'session_id': session.id},
        retryOperation: () => _apiService.createBreathingSession(session),
        retryConfig: const RetryConfig(maxAttempts: 2),
      );
    }
  }

  /// Enhanced get breathing sessions
  Future<List<BreathingSessionData>> getBreathingSessions() async {
    try {
      return await _circuitBreakerManager.execute<List<BreathingSessionData>>(
        name: 'breathing_sessions_get',
        operation: () => _apiService.getBreathingSessions(),
        fallback: () async {
          final localSessions = await _sqliteHelper.getAllBreathingSessions();
          logger.i(
            'Returning ${localSessions.length} local breathing sessions',
          );
          return localSessions;
        },
        config: _fastConfig,
      );
    } catch (e, stackTrace) {
      final result = await _errorHandler
          .handleError<List<BreathingSessionData>>(
            error: e,
            stackTrace: stackTrace,
            operation: 'get_breathing_sessions',
            retryOperation: () => _apiService.getBreathingSessions(),
            retryConfig: const RetryConfig(maxAttempts: 2),
            showToUser: false,
          );

      if (result == null) {
        final localSessions = await _sqliteHelper.getAllBreathingSessions();
        logger.i(
          'Fallback: returning ${localSessions.length} local breathing sessions',
        );
        return localSessions;
      }

      return result;
    }
  }

  /// Enhanced breathing pattern creation
  Future<BreathingPattern?> createBreathingPattern(
    BreathingPattern pattern,
  ) async {
    try {
      return await _circuitBreakerManager.execute<BreathingPattern>(
        name: 'breathing_patterns_create',
        operation: () => _apiService.createBreathingPattern(pattern),
        fallback: () async {
          await _sqliteHelper.insertBreathingPattern(pattern);
          logger.i('Stored breathing pattern locally for later sync');
          return pattern;
        },
        config: _defaultConfig,
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError<BreathingPattern>(
        error: e,
        stackTrace: stackTrace,
        operation: 'create_breathing_pattern',
        context: {'pattern_id': pattern.id},
        retryOperation: () => _apiService.createBreathingPattern(pattern),
        retryConfig: const RetryConfig(maxAttempts: 2),
      );
    }
  }

  /// Enhanced get breathing patterns
  Future<List<BreathingPattern>> getBreathingPatterns() async {
    try {
      return await _circuitBreakerManager.execute<List<BreathingPattern>>(
        name: 'breathing_patterns_get',
        operation: () => _apiService.getBreathingPatterns(),
        fallback: () async {
          final localPatterns = await _sqliteHelper.getAllBreathingPatterns();
          return localPatterns;
        },
        config: _fastConfig,
      );
    } catch (e, stackTrace) {
      final result = await _errorHandler.handleError<List<BreathingPattern>>(
        error: e,
        stackTrace: stackTrace,
        operation: 'get_breathing_patterns',
        retryOperation: () => _apiService.getBreathingPatterns(),
        retryConfig: const RetryConfig(maxAttempts: 2),
        showToUser: false,
      );

      if (result == null) {
        final localPatterns = await _sqliteHelper.getAllBreathingPatterns();
        return localPatterns;
      }

      return result;
    }
  }

  /// Enhanced custom emotion creation
  Future<CustomEmotion?> createCustomEmotion(CustomEmotion emotion) async {
    try {
      return await _circuitBreakerManager.execute<CustomEmotion>(
        name: 'custom_emotions_create',
        operation: () => _apiService.createCustomEmotion(emotion),
        fallback: () async {
          await _sqliteHelper.insertCustomEmotion(emotion);
          logger.i('Stored custom emotion locally for later sync');
          return emotion;
        },
        config: _defaultConfig,
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError<CustomEmotion>(
        error: e,
        stackTrace: stackTrace,
        operation: 'create_custom_emotion',
        context: {'emotion_id': emotion.id},
        retryOperation: () => _apiService.createCustomEmotion(emotion),
        retryConfig: const RetryConfig(maxAttempts: 2),
      );
    }
  }

  /// Enhanced get custom emotions
  Future<List<CustomEmotion>> getCustomEmotions() async {
    try {
      return await _circuitBreakerManager.execute<List<CustomEmotion>>(
        name: 'custom_emotions_get',
        operation: () => _apiService.getCustomEmotions(),
        fallback: () async {
          final localEmotions = await _sqliteHelper.getAllCustomEmotions();
          logger.i('Returning ${localEmotions.length} local custom emotions');
          return localEmotions;
        },
        config: _fastConfig,
      );
    } catch (e, stackTrace) {
      final result = await _errorHandler.handleError<List<CustomEmotion>>(
        error: e,
        stackTrace: stackTrace,
        operation: 'get_custom_emotions',
        retryOperation: () => _apiService.getCustomEmotions(),
        retryConfig: const RetryConfig(maxAttempts: 2),
        showToUser: false,
      );

      if (result == null) {
        final localEmotions = await _sqliteHelper.getAllCustomEmotions();
        logger.i(
          'Fallback: returning ${localEmotions.length} local custom emotions',
        );
        return localEmotions;
      }

      return result;
    }
  }

  /// Enhanced chat with fallback message
  Future<ChatResponse?> sendChatMessage(
    String message, {
    String agentType = 'therapy',
    Map<String, dynamic>? context,
  }) async {
    try {
      return await _circuitBreakerManager.execute<ChatResponse>(
        name: 'chat_send_message',
        operation:
            () => _apiService.sendChatMessage(
              message,
              agentType: agentType,
              context: context,
            ),
        fallback: () async {
          // Return a helpful offline message
          return ChatResponse(
            message:
                "I'm currently offline, but I've noted your message. "
                "I'll be able to provide personalized guidance once connection is restored. "
                "In the meantime, try some breathing exercises or record your emotions.",
            agentType: agentType,
            conversationId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
            crisisDetected: false,
            timestamp: DateTime.now(),
          );
        },
        config: _defaultConfig,
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError<ChatResponse>(
        error: e,
        stackTrace: stackTrace,
        operation: 'send_chat_message',
        context: {'agent_type': agentType, 'message_length': message.length},
        retryOperation:
            () => _apiService.sendChatMessage(
              message,
              agentType: agentType,
              context: context,
            ),
        retryConfig: const RetryConfig(maxAttempts: 2),
      );
    }
  }

  /// Enhanced user limitations with default fallback
  Future<UserLimitations> getUserLimitations() async {
    try {
      return await _circuitBreakerManager.execute<UserLimitations>(
        name: 'user_limitations_get',
        operation: () => _apiService.getUserLimitations(),
        fallback: () async {
          // Return generous defaults for offline use
          return UserLimitations(
            dailyTokenLimit: 1000,
            dailyTokensUsed: 0,
            isUnlimited: true,
            canMakeRequest: true,
            dailyCostLimit: 100.0,
            dailyCostUsed: 0.0,
          );
        },
        config: _fastConfig,
      );
    } catch (e, stackTrace) {
      final result = await _errorHandler.handleError<UserLimitations>(
        error: e,
        stackTrace: stackTrace,
        operation: 'get_user_limitations',
        retryOperation: () => _apiService.getUserLimitations(),
        retryConfig: const RetryConfig(maxAttempts: 1),
        showToUser: false,
      );

      if (result == null) {
        return UserLimitations(
          dailyTokenLimit: 1000,
          dailyTokensUsed: 0,
          isUnlimited: true,
          canMakeRequest: true,
          dailyCostLimit: 100.0,
          dailyCostUsed: 0.0,
        );
      }

      return result;
    }
  }

  /// Health check with circuit breaker
  Future<bool> checkHealth() async {
    try {
      return await _circuitBreakerManager.execute<bool>(
        name: 'health_check',
        operation: () => _apiService.checkHealth(),
        fallback: () async => false,
        config: const CircuitBreakerConfig(
          failureThreshold: 1,
          timeout: Duration(seconds: 5),
          retryDelay: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Get circuit breaker status for monitoring
  Map<String, dynamic> getCircuitBreakerStatus() {
    return {
      'circuitBreakers': _circuitBreakerManager.getAllStatus(),
      'openBreakers': _circuitBreakerManager.getOpenCircuitBreakers(),
      'hasOpenBreakers': _circuitBreakerManager.hasOpenCircuitBreakers(),
    };
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    return _errorHandler.getErrorStats();
  }

  /// Reset all circuit breakers (for manual recovery)
  void resetCircuitBreakers() {
    _circuitBreakerManager.resetAll();
  }

  /// Passthrough methods that don't need enhancement
  Future<void> logout() => _apiService.logout();

  Future<List<Map<String, dynamic>>> getAgents() => _apiService.getAgents();

  Future<Map<String, dynamic>> getAgentStatus(String agentType) =>
      _apiService.getAgentStatus(agentType);

  Future<void> clearAgentMemory(String agentType) =>
      _apiService.clearAgentMemory(agentType);

  Future<List<Map<String, dynamic>>> getConversations() =>
      _apiService.getConversations();
}
