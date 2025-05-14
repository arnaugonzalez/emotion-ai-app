import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app/router.dart';
import 'shared/services/sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Placeholder for offline usage setup (e.g., local caching)
  await initializeOfflineStorage();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> initializeOfflineStorage() async {
  final sqliteHelper = SQLiteHelper();
  await sqliteHelper.database; // Ensure the database is initialized
  logger.i("Offline storage initialized");

  // Attempt to sync offline data with the backend
  await syncOfflineData(sqliteHelper);
}

Future<void> syncOfflineData(SQLiteHelper sqliteHelper) async {
  final unsyncedEmotionalRecords =
      await sqliteHelper.getUnsyncedEmotionalRecords();
  for (final record in unsyncedEmotionalRecords) {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/emotional_records/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toMap()),
      );

      if (response.statusCode == 200) {
        await sqliteHelper.markEmotionalRecordAsSynced(record.id!);
        logger.i('Synced emotional record: ${record.description}');
      }
    } catch (e) {
      logger.e('Error syncing emotional record: $e');
    }
  }

  // Sync Breathing Sessions
  final unsyncedBreathingSessions =
      await sqliteHelper.getUnsyncedBreathingSessions();
  for (final session in unsyncedBreathingSessions) {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/breathing_sessions/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(session.toMap()),
      );

      if (response.statusCode == 200) {
        await sqliteHelper.markBreathingSessionAsSynced(session.id!);
        print('Synced breathing session with rating: ${session.rating}');
      } else {
        print(
          'Failed to sync breathing session with rating: ${session.rating}',
        );
      }
    } catch (e) {
      print('Error syncing breathing session: $e');
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      title: 'E-MOTION AI',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pinkAccent),
    );
  }
}
