import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'app/router.dart';
import 'shared/services/sqlite_helper.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart' as provider;
import 'features/calendar/events/calendar_events_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');

  // Initialize OpenAI with API key
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey != null && apiKey.isNotEmpty) {
    OpenAI.apiKey = apiKey;
    OpenAI.showLogs = kDebugMode; // Enable logs in debug mode only
    OpenAI.requestsTimeOut = const Duration(seconds: 30);
    logger.i("OpenAI API initialized");
  } else {
    logger.e("OpenAI API key not found in environment variables");
  }

  // Platform-specific optimizations
  if (!kIsWeb) {
    // Disable debug flags in release mode
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
  }

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter error: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  // Set up async error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Platform error: $error\n$stack');
    return true;
  };

  try {
    await initializeOfflineStorage();
  } catch (e, st) {
    logger.e('Initialization failed: $e\n$st');
  }

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => CalendarEventsProvider(),
        ),
        // ...other providers
      ],
      child: const ProviderScope(child: ErrorBoundary(child: MyApp())),
    ),
  );
}

Future<void> initializeOfflineStorage() async {
  final sqliteHelper = SQLiteHelper();
  try {
    await sqliteHelper.database.timeout(const Duration(seconds: 5));
    logger.i("Offline storage initialized");
    await syncOfflineData(sqliteHelper).timeout(const Duration(seconds: 5));
  } catch (e, st) {
    logger.e("Offline storage init failed ERROR: $e : $st");
    // Don't throw, just log
  }
}

Future<void> syncOfflineData(SQLiteHelper sqliteHelper) async {
  // Sync emotional records
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
        logger.i('Synced breathing session with rating: ${session.rating}');
      } else {
        logger.e(
          'Failed to sync breathing session with rating: ${session.rating}',
        );
      }
    } catch (e) {
      logger.e('Error syncing breathing session: $e');
    }
  }

  // Sync Breathing Patterns
  try {
    final unsyncedBreathingPatterns =
        await sqliteHelper.getUnsyncedBreathingPatterns();

    for (final patternMap in unsyncedBreathingPatterns) {
      try {
        final url = Uri.parse('http://10.0.2.2:8000/breathing_patterns/');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(patternMap),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await sqliteHelper.markBreathingPatternAsSynced(
            patternMap['id'] as int,
          );
          logger.i('Synced breathing pattern: ${patternMap['name']}');
        } else {
          logger.e(
            'Failed to sync breathing pattern: ${patternMap['name']} - Status: ${response.statusCode}',
          );
        }
      } catch (e) {
        logger.e('Error syncing breathing pattern: $e');
      }
    }
  } catch (e) {
    // This might happen if the breathing_patterns table doesn't exist yet
    logger.e('Error accessing breathing patterns: $e');
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    };

    return child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      title: 'E-MOTION AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pinkAccent,
        // Add more theme configurations for consistency
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
