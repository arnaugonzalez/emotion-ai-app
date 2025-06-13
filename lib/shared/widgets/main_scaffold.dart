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
    final iconSize = 32.0; // Increased icon size

    final navigationDestinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined, size: iconSize),
        selectedIcon: Icon(Icons.home, size: iconSize),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined, size: iconSize),
        selectedIcon: Icon(Icons.calendar_today, size: iconSize),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.palette_outlined, size: iconSize),
        selectedIcon: Icon(Icons.palette, size: iconSize),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.self_improvement_outlined, size: iconSize),
        selectedIcon: Icon(Icons.self_improvement, size: iconSize),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined, size: iconSize),
        selectedIcon: Icon(Icons.analytics, size: iconSize),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(
          Icons.psychology_outlined,
          size: iconSize,
          color: Colors.green,
        ),
        selectedIcon: Icon(
          Icons.psychology,
          size: iconSize,
          color: Colors.green,
        ),
        label: '',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, size: iconSize),
        selectedIcon: Icon(Icons.person, size: iconSize),
        label: '',
      ),
    ];

    final railDestinations = [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined, size: iconSize),
        selectedIcon: Icon(Icons.home, size: iconSize),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calendar_today_outlined, size: iconSize),
        selectedIcon: Icon(Icons.calendar_today, size: iconSize),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.palette_outlined, size: iconSize),
        selectedIcon: Icon(Icons.palette, size: iconSize),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.self_improvement_outlined, size: iconSize),
        selectedIcon: Icon(Icons.self_improvement, size: iconSize),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined, size: iconSize),
        selectedIcon: Icon(Icons.analytics, size: iconSize),
        label: const Text(''),
      ),
      NavigationRailDestination(
        padding: const EdgeInsets.only(top: 32),
        icon: Icon(
          Icons.psychology_outlined,
          size: iconSize,
          color: Colors.green,
        ),
        selectedIcon: Icon(
          Icons.psychology,
          size: iconSize,
          color: Colors.green,
        ),
        label: const Text(''),
      ),
      NavigationRailDestination(
        padding: const EdgeInsets.only(top: 48),
        icon: Icon(Icons.person_outline, size: iconSize),
        selectedIcon: Icon(Icons.person, size: iconSize),
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
              minWidth: 80,
              minExtendedWidth: 80,
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
          height: 80,
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
