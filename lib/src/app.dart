import 'package:dynamic_color/dynamic_color.dart'; // Added for Material You
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'services/theme/theme_service.dart';

class FitFlowApp extends ConsumerWidget {
  const FitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the router from the provider
    final router = ref.watch(goRouterProvider);

    // Get the current theme mode from the theme provider
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Create theme based on dynamic colors or fallback to defaults
        final lightColorScheme = lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            );

        final darkColorScheme = darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            );

        return MaterialApp.router(
          title: 'FitFlow',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: themeMode, // Use the theme mode from the provider
          routerConfig: router,
        );
      },
    );
  }
}
