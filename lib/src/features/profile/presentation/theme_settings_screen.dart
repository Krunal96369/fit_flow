import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/theme/theme_service.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Choose Theme',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Theme'),
            subtitle: const Text('Follow your device settings'),
            value: ThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            subtitle: const Text('Always use light theme'),
            value: ThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            subtitle: const Text('Always use dark theme'),
            value: ThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
            },
          ),

          const Divider(),

          // Theme preview
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                        'Theme Preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is how text and components will look with the selected theme.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Button'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Button'),
                          ),
                        ],
                      ),
                    ],
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
