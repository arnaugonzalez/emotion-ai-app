import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/router.dart';
import 'shared/models/emotional_record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(EmotionalRecordAdapter());
  Hive.registerAdapter(EmotionAdapter());
  await Hive.openBox<EmotionalRecord>('registers');

  runApp(const ProviderScope(child: MyApp()));
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
