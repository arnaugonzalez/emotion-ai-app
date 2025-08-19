import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_profile.dart';
import '../models/therapy_context.dart';
import '../../config/api_config.dart';

class ProfileService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ProfileService();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/'),
        headers: await _getHeaders(),
      );

      print('DEBUG: Profile API response status: ${response.statusCode}');
      print('DEBUG: Profile API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed profile data: $data');

        try {
          final profile = UserProfile.fromJson(data);
          print('DEBUG: Successfully created UserProfile object');
          return profile;
        } catch (parseError) {
          print('DEBUG: Error parsing profile data: $parseError');
          print('DEBUG: Data that failed to parse: $data');
          throw Exception('Failed to parse profile data: $parseError');
        }
      } else if (response.statusCode == 404) {
        print('DEBUG: Profile not found (404)');
        return null; // Profile not found
      } else {
        print(
          'DEBUG: Profile API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in getUserProfile: $e');
      throw Exception('Error getting profile: $e');
    }
  }

  /// Create or update user profile
  Future<UserProfile> createOrUpdateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/profile/'),
        headers: await _getHeaders(),
        body: json.encode(profileData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to save profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving profile: $e');
    }
  }

  /// Get profile completion status
  Future<ProfileStatus> getProfileStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileStatus.fromJson(data);
      } else {
        throw Exception('Failed to get profile status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting profile status: $e');
    }
  }

  /// Get therapy context and AI insights
  Future<TherapyContext?> getTherapyContext() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/therapy-context'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TherapyContext.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // No therapy context found
      } else {
        throw Exception(
          'Failed to get therapy context: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting therapy context: $e');
    }
  }

  /// Update therapy context and AI insights
  Future<TherapyContext> updateTherapyContext(
    Map<String, dynamic> contextData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/therapy-context'),
        headers: await _getHeaders(),
        body: json.encode(contextData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TherapyContext.fromJson(data);
      } else {
        throw Exception(
          'Failed to update therapy context: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating therapy context: $e');
    }
  }

  /// Clear therapy context and AI insights
  Future<bool> clearTherapyContext() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/profile/therapy-context'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error clearing therapy context: $e');
    }
  }

  /// Get AI agent personality settings and context
  Future<Map<String, dynamic>?> getAgentPersonality() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/agent-personality'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        return null; // No agent personality data found
      } else {
        throw Exception(
          'Failed to get agent personality: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting agent personality: $e');
    }
  }

  /// Update AI agent personality settings and context
  Future<Map<String, dynamic>> updateAgentPersonality(
    Map<String, dynamic> personalityData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/agent-personality'),
        headers: await _getHeaders(),
        body: json.encode(personalityData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to update agent personality: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating agent personality: $e');
    }
  }
}
