import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/user.dart';
import 'models/auth_response.dart';
import 'models/chat_response.dart';
import 'models/breathing_pattern.dart';
import 'models/breathing_session.dart';
import 'models/custom_emotion.dart';
import 'models/emotional_record.dart';
import 'models/user_limitations.dart';
import '../config/api_config.dart';

import '../utils/data_validator.dart';
import 'package:logger/logger.dart';
import 'exceptions/api_exceptions.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Public getter for headers (used by sync service)
  Future<Map<String, String>> getHeaders() async {
    return await _getHeaders();
  }

  /// Handle HTTP response and throw appropriate exceptions
  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = jsonDecode(response.body);
        return parser(responseData);
      } catch (e) {
        _logger.e('Failed to parse response: $e');
        throw UnknownApiException('Invalid response format');
      }
    } else {
      throw ApiExceptionFactory.fromResponse(
        response.statusCode,
        response.body,
        defaultMessage: 'Request failed with status ${response.statusCode}',
      );
    }
  }

  /// Handle HTTP response for list endpoints
  List<T> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is! List) {
          throw UnknownApiException(
            'Expected list response, got: ${responseData.runtimeType}',
          );
        }

        final List<dynamic> data = responseData;
        _logger.i('Processing ${data.length} items');

        // Validate each item before parsing
        final validatedData = DataValidator.validateApiResponseList(
          data,
          T.toString(),
        );

        return validatedData.map((json) => parser(json)).toList();
      } catch (e) {
        if (e is ApiException) rethrow;
        _logger.e('Failed to parse list response: $e');
        throw UnknownApiException('Invalid response format');
      }
    } else {
      throw ApiExceptionFactory.fromResponse(
        response.statusCode,
        response.body,
        defaultMessage: 'Request failed with status ${response.statusCode}',
      );
    }
  }

  Future<User> createUser(
    String email,
    String password,
    String firstName,
    String lastName, {
    DateTime? dateOfBirth,
  }) async {
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    };

    if (dateOfBirth != null) {
      requestBody['date_of_birth'] = dateOfBirth.toIso8601String();
    }

    final response = await http.post(
      Uri.parse(ApiConfig.registerUrl()),
      headers: await _getHeaders(),
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _setToken(authResponse.accessToken);
      return authResponse.user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create user');
    }
  }

  Future<AuthResponse?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl()),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _setToken(authResponse.accessToken);
      // Store token expiry time for future reference
      final expiryTime = DateTime.now().add(
        Duration(seconds: authResponse.expiresIn),
      );
      await _storage.write(
        key: 'token_expiry',
        value: expiryTime.toIso8601String(),
      );
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // Emotional Records
  Future<EmotionalRecord> createEmotionalRecord(EmotionalRecord record) async {
    _logger.i(
      '📤 Creating emotional record: ${record.emotion} (intensity: ${record.intensity})',
    );

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.emotionalRecordsUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(record.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      _logger.i('📥 Emotional record response: ${response.statusCode}');

      return _handleResponse(response, (data) {
        _logger.i('✅ Emotional record created successfully: ${data['id']}');
        return EmotionalRecord.fromJson(data);
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.e('❌ Network error creating emotional record: $e');
      throw ApiExceptionFactory.fromException(e);
    }
  }

  Future<List<EmotionalRecord>> getEmotionalRecords() async {
    try {
      _logger.i(
        'Fetching emotional records from ${ApiConfig.emotionalRecordsUrl()}',
      );

      final response = await http.get(
        Uri.parse(ApiConfig.emotionalRecordsUrl()),
        headers: await _getHeaders(),
      );

      _logger.i('Emotional records response: ${response.statusCode}');

      return _handleListResponse(
        response,
        (json) => EmotionalRecord.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.e('Error fetching emotional records: $e');
      throw ApiExceptionFactory.fromException(e);
    }
  }

  // Breathing Sessions
  Future<BreathingSessionData> createBreathingSession(
    BreathingSessionData session,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.breathingSessionsUrl()),
        headers: await _getHeaders(),
        body: jsonEncode(session.toJson()),
      );

      return _handleResponse(
        response,
        (data) => BreathingSessionData.fromJson(data),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiExceptionFactory.fromException(e);
    }
  }

  Future<List<BreathingSessionData>> getBreathingSessions() async {
    try {
      _logger.i(
        'Fetching breathing sessions from ${ApiConfig.breathingSessionsUrl()}',
      );

      final response = await http.get(
        Uri.parse(ApiConfig.breathingSessionsUrl()),
        headers: await _getHeaders(),
      );

      _logger.i('Breathing sessions response: ${response.statusCode}');

      return _handleListResponse(
        response,
        (json) => BreathingSessionData.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.e('Error fetching breathing sessions: $e');
      throw ApiExceptionFactory.fromException(e);
    }
  }

  // Breathing Patterns
  Future<BreathingPattern> createBreathingPattern(
    BreathingPattern pattern,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.breathingPatternsUrl()),
        headers: await _getHeaders(),
        body: jsonEncode(pattern.toJson()),
      );

      return _handleResponse(
        response,
        (data) => BreathingPattern.fromJson(data),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiExceptionFactory.fromException(e);
    }
  }

  Future<List<BreathingPattern>> getBreathingPatterns() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.breathingPatternsUrl()),
        headers: await _getHeaders(),
      );

      return _handleListResponse(
        response,
        (json) => BreathingPattern.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiExceptionFactory.fromException(e);
    }
  }

  // Custom Emotions
  Future<CustomEmotion> createCustomEmotion(CustomEmotion emotion) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/custom_emotions/'),
        headers: await _getHeaders(),
        body: jsonEncode(emotion.toJson()),
      );

      return _handleResponse(response, (data) => CustomEmotion.fromJson(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiExceptionFactory.fromException(e);
    }
  }

  Future<List<CustomEmotion>> getCustomEmotions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/custom_emotions/'),
        headers: await _getHeaders(),
      );

      return _handleListResponse(
        response,
        (json) => CustomEmotion.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiExceptionFactory.fromException(e);
    }
  }

  // User Limitations (from backend)
  Future<UserLimitations> getUserLimitations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/limitations'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return UserLimitations.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user limitations');
    }
  }

  // Send chat message to backend using new API structure
  Future<ChatResponse> sendChatMessage(
    String message, {
    String agentType = 'therapy',
    Map<String, dynamic>? context,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.chatUrl()),
      headers: await _getHeaders(),
      body: jsonEncode({
        'agent_type': agentType,
        'message': message,
        if (context != null) 'context': context,
      }),
    );

    if (response.statusCode == 200) {
      return ChatResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 429) {
      // Rate limited
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? error['detail'] ?? 'Rate limit exceeded',
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send chat message');
    }
  }

  // Get available agents
  Future<List<Map<String, dynamic>>> getAgents() async {
    final response = await http.get(
      Uri.parse(ApiConfig.agentsListUrl()),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['agents']);
    } else {
      throw Exception('Failed to get agents');
    }
  }

  // Get agent status
  Future<Map<String, dynamic>> getAgentStatus(String agentType) async {
    final response = await http.get(
      Uri.parse(ApiConfig.agentStatusUrl(agentType)),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get agent status');
    }
  }

  // Clear agent memory
  Future<void> clearAgentMemory(String agentType) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/agents/$agentType/memory'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear agent memory');
    }
  }

  // Get conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/conversations'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get conversations');
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.healthUrl()));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
