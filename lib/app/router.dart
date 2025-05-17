import 'package:emotion_ai/features/breathing_menu/breathing_menu.dart';
import 'package:emotion_ai/shared/widgets/main_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar.dart';
import '../features/color_wheel/color_wheel.dart';
import '../features/records/all_records_screen.dart';
import '../features/therapy_chat/screens/therapy_chat_screen.dart';
import '../features/profile/profile_screen.dart';

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
          GoRoute(
            path: '/breathing_menu',
            name: 'Breathing Menu',
            builder: (context, state) => const BreathingMenuScreen(),
          ),
          GoRoute(
            path: '/all_records',
            name: 'All Records',
            builder: (context, state) => const AllRecordsScreen(),
          ),
          GoRoute(
            path: '/therapy_chat',
            name: 'Talk it Through',
            builder: (context, state) => const TherapyChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'Profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
