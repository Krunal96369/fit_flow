import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/accessibility/accessibility_service.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        children: [
          // Text size section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Text Size',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Adjust the size of text throughout the app'),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text('A', style: TextStyle(fontSize: 14)),
                Expanded(child: SizedBox()),
                Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
          Slider(
            value: textScaleFactor,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(textScaleFactor * 100).round()}%',
            onChanged: (value) {
              ref
                  .read(textScaleFactorProvider.notifier)
                  .setTextScaleFactor(value);
            },
          ),

          // Text preview
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text Size Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how text will appear throughout the app with your current settings.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Motion effects
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Motion',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Reduce Motion'),
            subtitle: const Text('Minimize animations throughout the app'),
            value: reducedMotion,
            onChanged: (value) {
              ref.read(reducedMotionProvider.notifier).setReducedMotion(value);
            },
          ),

          const Divider(),

          // Information section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Accessibility',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'FitFlow is designed to be accessible to all users. These settings help customize your experience to your specific needs.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'If you have feedback on how we can improve accessibility, please contact us.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
