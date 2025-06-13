import 'package:emotion_ai/features/breathing_menu/breathing_menu.dart';
import 'package:emotion_ai/shared/widgets/main_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar.dart';
import '../features/color_wheel/color_wheel.dart';
import '../features/records/all_records_screen.dart';
import '../features/therapy_chat/screens/therapy_chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/breating_session.dart';
import '../shared/models/breathing_pattern.dart';
import '../features/auth/pin_code_screen.dart';

// Provider to track if this is the first launch after app start
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Get the current isFirstLaunch value
      final isFirstLaunchValue = ref.read(isFirstLaunchProvider);

      // Check if PIN code is required
      final prefs = await SharedPreferences.getInstance();
      final hasPin = prefs.getString('user_pin_code') != null;
      final hasVerifiedPin = prefs.getBool('pin_verified') ?? false;

      // If this is the first launch after app start and PIN is set but not verified
      if (isFirstLaunchValue &&
          hasPin &&
          !hasVerifiedPin &&
          state.uri.path != '/pin') {
        return '/pin';
      }

      // If this is the first launch and no PIN is set, redirect to profile
      if (isFirstLaunchValue && !hasPin && state.uri.path != '/profile') {
        return '/profile';
      }

      // If we've passed the PIN check or profile setup, mark first launch as complete
      if (isFirstLaunchValue) {
        ref.read(isFirstLaunchProvider.notifier).state = false;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/pin', builder: (context, state) => const PinCodeScreen()),
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
            routes: [
              GoRoute(
                path: 'session',
                name: 'Breathing Session',
                builder: (context, state) {
                  final pattern = state.extra as BreathingPattern;
                  return BreathingSessionScreen(pattern: pattern);
                },
              ),
            ],
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
