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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Profile not found
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
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

  /// Update therapy context
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

  /// Clear therapy context
  Future<bool> clearTherapyContext() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/profile/therapy-context'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to clear therapy context: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error clearing therapy context: $e');
    }
  }

  /// Generate new AI insights
  Future<Map<String, dynamic>?> generateAIInsights() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/profile/generate-insights'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['insights'] as Map<String, dynamic>?;
      } else {
        throw Exception(
          'Failed to generate AI insights: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error generating AI insights: $e');
    }
  }

  /// Check if user has profile
  Future<bool> hasProfile() async {
    try {
      final status = await getProfileStatus();
      return status.hasProfile;
    } catch (e) {
      return false;
    }
  }

  /// Get profile completeness percentage
  Future<double> getProfileCompleteness() async {
    try {
      final status = await getProfileStatus();
      return status.profileCompleteness;
    } catch (e) {
      return 0.0;
    }
  }
}
