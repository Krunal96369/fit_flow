import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/app_scaffold.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart'; // Import SignUpScreen
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/nutrition/nutrition_router.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/nutrition_goals_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/security_settings_screen.dart';
import '../features/workouts/workout_router.dart';

// Placeholder screens for routes we haven't implemented yet
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      showBackButton: true,
      body: Center(child: Text('$title Screen Coming Soon')),
    );
  }
}

/// Helper function to determine if a route should show the bottom navigation bar
bool shouldShowBottomNavBar(String path) {
  // Don't show nav bar on authentication or onboarding screens
  if (path.startsWith('/sign-in') ||
      path.startsWith('/sign-up') ||
      path.startsWith('/onboarding')) {
    return false;
  }

  // Don't show nav bar on detail screens with back buttons
  if (path.contains('/add') ||
      path.contains('/edit') ||
      path.contains('/details') ||
      path.contains('/settings') ||
      path.contains('/reset-password') ||
      path.contains('/change-password')) {
    return false;
  }

  // Show on main navigation screens
  return true;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch for changes to the onboarding and auth states
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // First check if onboarding is completed
      if (!onboardingCompleted && state.fullPath != '/onboarding') {
        return '/onboarding';
      }

      // Then check authentication
      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );

      // Allow access to auth screens if not logged in
      final isLoginRelatedScreen = state.fullPath == '/sign-in' ||
          state.fullPath == '/sign-up' ||
          state.fullPath == '/reset-password' ||
          state.fullPath?.startsWith('/reset-password') == true;

      // Screens that require authentication but shouldn't redirect to dashboard when logged in
      final isAuthRequiredSpecialScreen =
          state.fullPath == '/change-password' ||
              state.fullPath == '/settings/security';

      // If not logged in and not on an auth screen or onboarding, redirect to login
      if (!isLoggedIn &&
          !isLoginRelatedScreen &&
          !isAuthRequiredSpecialScreen &&
          onboardingCompleted &&
          state.fullPath != '/onboarding') {
        return state.path ?? '/sign-in';
      }

      // If logged in and on a login-related screen, redirect to dashboard
      if (isLoggedIn && isLoginRelatedScreen) {
        return '/dashboard';
      }

      // No redirection needed
      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        // Add route for SignUpScreen
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Dashboard (main screen)
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Nutrition routes
      ...nutritionRoutes,

      // Workout routes
      ...workoutRoutes,

      // Profile & Settings routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/nutrition-goals',
        builder: (context, state) => const NutritionGoalsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Theme Settings'),
      ),
      GoRoute(
        path: '/settings/accessibility',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Accessibility'),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/export',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Export Data'),
      ),
    ],
  );
});
