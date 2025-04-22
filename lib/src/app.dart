import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'services/theme/custom_colors.dart';
import 'services/theme/theme_service.dart';

class FitFlowApp extends ConsumerWidget {
  const FitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
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
          debugShowCheckedModeBanner: false,
          title: 'FitFlow',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            extensions: [
              CustomColors.light(),
            ],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            extensions: [
              CustomColors.dark(),
            ],
          ),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
