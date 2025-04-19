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
              ];
              context.go(routes[index]);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Inici'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month),
                label: Text('Calendari'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.palette),
                label: Text('Emocions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.music_note),
                label: Text('Respiracions'),
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
      default:
        return 0;
    }
  }
}
