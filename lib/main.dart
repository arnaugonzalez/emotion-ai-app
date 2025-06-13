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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize critical features in parallel
  final futures = await Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    SharedPreferences.getInstance(),
    dotenv.load(fileName: 'assets/.env'),
  ]);

  final prefs = futures[1] as SharedPreferences;
  await prefs.setBool('pin_verified', false);

  // Initialize OpenAI with API key
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey != null && apiKey.isNotEmpty) {
    OpenAI.apiKey = apiKey;
    OpenAI.showLogs = kDebugMode;
    OpenAI.requestsTimeOut = const Duration(seconds: 30);
    logger.i("OpenAI API initialized");
  } else {
    logger.e("OpenAI API key not found in environment variables");
  }

  // Platform-specific optimizations
  if (!kIsWeb && kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter error: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Platform error: $error\n$stack');
    return true;
  };

  // Initialize app and defer non-critical operations
  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => CalendarEventsProvider(),
        ),
      ],
      child: const ProviderScope(child: MyApp()),
    ),
  );

  // Initialize offline storage in background after app is launched
  Future.microtask(() => initializeOfflineStorage());
}

Future<void> initializeOfflineStorage() async {
  final sqliteHelper = SQLiteHelper();
  try {
    await sqliteHelper.database.timeout(const Duration(seconds: 5));
    logger.i("Offline storage initialized");

    // Only sync if there's network connectivity
    if (await _checkConnectivity()) {
      await syncOfflineData(sqliteHelper).timeout(const Duration(seconds: 5));
    }
  } catch (e, st) {
    logger.e("Offline storage init failed ERROR: $e : $st");
  }
}

Future<bool> _checkConnectivity() async {
  try {
    final result = await http.get(Uri.parse('http://10.0.2.2:8000/health'));
    return result.statusCode == 200;
  } catch (e) {
    return false;
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is being killed or sent to background
      ref.read(isFirstLaunchProvider.notifier).state = true;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('pin_verified', false);
      });
    } else if (state == AppLifecycleState.resumed) {
      // App is being resumed
      ref.read(isFirstLaunchProvider.notifier).state = true;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('pin_verified', false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'E-motion AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
