import 'package:emotion_ai/shared/widgets/main_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar.dart';
import '../features/color_wheel/color_wheel.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'Calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/color_wheel',
            name: 'Color Wheel',
            builder: (context, state) => const ColorWheelScreen(),
          ),
        ],
      ),
    ],
  );
});
