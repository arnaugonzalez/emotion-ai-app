import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/breathing_session.dart';
import '../../config/api_config.dart';
import '../services/sqlite_helper.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

final logger = Logger();

class BreathingSessionNotifier extends StateNotifier<BreathingSessionData?> {
  BreathingSessionNotifier() : super(null);

  Future<void> saveSession(BreathingSessionData session) async {
    final url = Uri.parse(ApiConfig.breathingSessionsUrl());
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(session.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to save session to backend: ${response.statusCode}',
        );
      }

      logger.i('Session saved to backend successfully');
    } catch (e) {
      logger.w('Failed to save to backend, falling back to local storage: $e');
      // Fallback to SQLite if the backend is unreachable
      try {
        final sqliteHelper = SQLiteHelper();
        await sqliteHelper.insertBreathingSession(session);
        logger.i('Session saved locally successfully');
      } catch (e) {
        logger.e('Failed to save session locally: $e');
        rethrow; // Re-throw to let UI handle the error
      }
    }
  }
}

final breathingSessionProvider =
    StateNotifierProvider<BreathingSessionNotifier, BreathingSessionData?>(
      (ref) => BreathingSessionNotifier(),
    );
