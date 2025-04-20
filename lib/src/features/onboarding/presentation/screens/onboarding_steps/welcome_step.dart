import 'package:flutter/material.dart';

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
          Icon(
            Icons.fitness_center,
            size: 80,
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
          const Text(
            'Your personalized fitness companion for tracking workouts, nutrition, and achieving your health goals.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
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

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 30,
            color: primaryColor,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
