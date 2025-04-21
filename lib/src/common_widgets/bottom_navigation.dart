import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/app_logo.dart';

/// A common bottom navigation bar that can be used across all screens
/// Uses Material 3 NavigationBar (updated version of BottomNavigationBar)
class AppBottomNavigation extends StatelessWidget {
  /// Current route path to determine which tab is active
  final String currentPath;

  /// Constructor
  const AppBottomNavigation({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which tab is selected based on the current route
    int selectedIndex = _getSelectedIndex(currentPath);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: AppLogo(useImage: true, size: 24),
          selectedIcon: AppLogo(useImage: true, size: 24),
          label: 'Workouts',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Nutrition',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  /// Navigate to the appropriate route when a tab is tapped
  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/workouts/new');
        break;
      case 2:
        context.go('/nutrition');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  /// Determine which tab is selected based on the current route
  int _getSelectedIndex(String path) {
    if (path.startsWith('/dashboard')) {
      return 0;
    } else if (path.startsWith('/workouts')) {
      return 1;
    } else if (path.startsWith('/nutrition')) {
      return 2;
    } else if (path.startsWith('/profile')) {
      return 3;
    }
    return 0; // Default to dashboard
  }
}
