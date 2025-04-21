import 'package:flutter/material.dart';

import '../../../../../common_widgets/app_logo.dart';

/// The welcome step in the onboarding process
class WelcomeStep extends StatelessWidget {
  /// Constructor
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo
          AppLogo(
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 32),

          // Welcome title
          const Text(
            'Welcome to FitFlow',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Welcome description
          Text(
            'Your personalized fitness companion for tracking workouts, nutrition, and achieving your health goals.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Features showcase
          _buildFeatureItem(
            context: context,
            icon: Icons.fitness_center,
            title: 'Track Workouts',
            description: 'Log and analyze your fitness activities',
          ),

          const SizedBox(height: 24),

          _buildFeatureItem(
            context: context,
            icon: Icons.restaurant_menu,
            title: 'Monitor Nutrition',
            description: 'Log meals and track your nutritional intake',
          ),

          const SizedBox(height: 24),

          _buildFeatureItem(
            context: context,
            icon: Icons.show_chart,
            title: 'Track Progress',
            description: 'Visualize your improvements over time',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
