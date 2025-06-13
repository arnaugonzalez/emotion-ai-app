import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final navigationDestinations = [
      NavigationDestination(
        icon: Icon(Icons.home, size: 28),
        selectedIcon: Icon(Icons.home_filled, size: 28),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month, size: 28),
        selectedIcon: Icon(Icons.calendar_month_outlined, size: 28),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.palette, size: 28),
        selectedIcon: Icon(Icons.palette_outlined, size: 28),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.music_note, size: 28),
        selectedIcon: Icon(Icons.music_note_outlined, size: 28),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.list_alt, size: 28),
        selectedIcon: Icon(Icons.list_alt_outlined, size: 28),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline, size: 28, color: Colors.green),
        selectedIcon: Icon(Icons.chat_bubble, size: 28, color: Colors.green),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, size: 28),
        selectedIcon: Icon(Icons.person, size: 28),
        label: '',
      ),
    ];

    final railDestinations = [
      NavigationRailDestination(
        icon: Icon(Icons.home, size: 28),
        selectedIcon: Icon(Icons.home_filled, size: 28),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calendar_month, size: 28),
        selectedIcon: Icon(Icons.calendar_month_outlined, size: 28),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.palette, size: 28),
        selectedIcon: Icon(Icons.palette_outlined, size: 28),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.music_note, size: 28),
        selectedIcon: Icon(Icons.music_note_outlined, size: 28),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.list_alt, size: 28),
        selectedIcon: Icon(Icons.list_alt_outlined, size: 28),
        label: const Text(''),
      ),
      NavigationRailDestination(
        padding: const EdgeInsets.only(top: 32),
        icon: Icon(Icons.chat_bubble_outline, size: 28, color: Colors.green),
        selectedIcon: Icon(Icons.chat_bubble, size: 28, color: Colors.green),
        label: const Text(''),
      ),
      NavigationRailDestination(
        padding: const EdgeInsets.only(top: 48),
        icon: Icon(Icons.person_outline, size: 28),
        selectedIcon: Icon(Icons.person, size: 28),
        label: const Text(''),
      ),
    ];

    final routes = [
      '/',
      '/calendar',
      '/color_wheel',
      '/breathing_menu',
      '/all_records',
      '/therapy_chat',
      '/profile',
    ];

    void onDestinationSelected(int index) {
      context.go(routes[index]);
    }

    if (isLandscape) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _routeToIndex(currentRoute),
              onDestinationSelected: onDestinationSelected,
              destinations: railDestinations,
              labelType: NavigationRailLabelType.none,
              useIndicator: true,
              minWidth: 72,
              minExtendedWidth: 72,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _routeToIndex(currentRoute),
          onDestinationSelected: onDestinationSelected,
          destinations: navigationDestinations,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
      );
    }
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
