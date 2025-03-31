import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import 'bottom_navigation.dart';

/// A scaffold wrapper that includes the bottom navigation bar
/// This can be used across all screens to ensure a consistent layout
class AppScaffold extends StatelessWidget {
  /// The title to display in the app bar
  final String? title;

  /// The body of the scaffold
  final Widget body;

  /// Optional app bar actions
  final List<Widget>? actions;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Whether to show the back button in the app bar
  final bool showBackButton;

  /// Whether to show the bottom navigation bar
  /// If not provided, it will be determined automatically based on the route
  final bool? showBottomNavigation;

  /// Constructor
  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.showBottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current route to determine which tab is active
    final GoRouterState routerState = GoRouterState.of(context);
    final String path = routerState.fullPath ?? '/dashboard';

    // Determine whether to show the bottom navigation based on route or provided value
    final shouldShowNav = showBottomNavigation ?? shouldShowBottomNavBar(path);

    return Scaffold(
      appBar:
          title != null
              ? AppBar(
                title: Text(title!),
                automaticallyImplyLeading: showBackButton,
                actions: actions,
              )
              : null,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          shouldShowNav ? AppBottomNavigation(currentPath: path) : null,
    );
  }
}
