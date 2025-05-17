import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _routeToIndex(currentRoute),
            onDestinationSelected: (index) {
              final routes = [
                '/',
                '/calendar',
                '/color_wheel',
                '/breathing_menu',
                '/all_records',
                '/therapy_chat',
                '/profile',
              ];
              context.go(routes[index]);
            },
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('How are you?'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.calendar_month),
                label: Text('Calendar'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.palette),
                label: Text('Color Wheel'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.music_note),
                label: Text('Breathing'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('All Records'),
              ),

              // Custom padding creates a visual separation
              NavigationRailDestination(
                padding: const EdgeInsets.only(top: 24), // Adds space above
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.green, // Distinctive color
                ),
                selectedIcon: const Icon(
                  Icons.chat_bubble,
                  color: Colors.green,
                ),
                label: const Text(
                  'Talk it Through',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Profile at the bottom
              NavigationRailDestination(
                padding: const EdgeInsets.only(top: 32), // Adds space above
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Profile'),
              ),
            ],
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _routeToIndex(String route) {
    switch (route) {
      case '/calendar':
        return 1;
      case '/color_wheel':
        return 2;
      case '/breathing_menu':
        return 3;
      case '/all_records':
        return 4;
      case '/therapy_chat':
        return 5;
      case '/profile':
        return 6;
      default:
        return 0;
    }
  }
}
