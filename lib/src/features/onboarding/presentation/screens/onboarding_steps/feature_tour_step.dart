import 'package:flutter/material.dart';

/// Step for showcasing the app's key features
class FeatureTourStep extends StatelessWidget {
  /// Constructor
  const FeatureTourStep({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Feature colors derived from theme
    final List<Color> featureColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primary.withBlue(200),
      colorScheme.secondary.withRed(220),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'App Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Discover what FitFlow can do for your fitness journey',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 32),

            // Features list
            _buildFeatureCard(
              context: context,
              title: 'Workout Tracking',
              icon: Icons.fitness_center,
              description:
                  'Log exercises, sets, and reps with our intuitive workout tracker',
              color: featureColors[0],
            ),

            _buildFeatureCard(
              context: context,
              title: 'Nutrition Logging',
              icon: Icons.restaurant_menu,
              description:
                  'Track your meals, calories, and macros to optimize your diet',
              color: featureColors[1],
            ),

            _buildFeatureCard(
              context: context,
              title: 'Progress Analytics',
              icon: Icons.insights,
              description:
                  'Visualize your improvement with detailed charts and statistics',
              color: featureColors[2],
            ),

            _buildFeatureCard(
              context: context,
              title: 'Custom Workouts',
              icon: Icons.style,
              description: 'Create and save your own workout routines',
              color: featureColors[3],
            ),

            _buildFeatureCard(
              context: context,
              title: 'Reminders & Goals',
              icon: Icons.notifications_active,
              description:
                  'Set fitness goals and get reminders to stay on track',
              color: featureColors[4],
            ),

            const SizedBox(height: 16),

            // Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.secondary, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: colorScheme.secondary),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'You can access the full feature guide anytime from the Settings menu',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor =
        brightness == Brightness.light ? Colors.white : Colors.grey[800];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          color: backgroundColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Feature icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),

            const SizedBox(width: 16),

            // Feature details
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
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
