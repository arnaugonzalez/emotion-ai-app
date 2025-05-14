import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/breathing_session_data.dart';
import '../services/sqlite_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BreathingSessionNotifier extends StateNotifier<BreathingSessionData?> {
  BreathingSessionNotifier() : super(null);

  Future<void> saveSession(BreathingSessionData session) async {
    final url = Uri.parse('http://10.0.2.2:8000/breathing_sessions/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(session.toMap()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save session to backend');
      }
    } catch (e) {
      // Fallback to SQLite if the backend is unreachable
      final sqliteHelper = SQLiteHelper();
      await sqliteHelper.insertBreathingSession(session);
      print('Saved session locally due to error: $e');
    }
  }
}

final breathingSessionProvider =
    StateNotifierProvider<BreathingSessionNotifier, BreathingSessionData?>(
      (ref) => BreathingSessionNotifier(),
    );
