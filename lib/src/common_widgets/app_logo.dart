import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// A widget that displays the app logo
///
/// Can be used in two modes:
/// - Image mode (useImage: true) - displays the actual logo image
/// - Icon mode (useImage: false) - falls back to the Material fitness_center icon
class AppLogo extends StatelessWidget {
  /// The size of the logo
  final double size;

  /// The color to apply to the logo (only applies to icon mode)
  final Color? color;

  /// Whether to use the image asset or fall back to icon
  final bool useImage;

  /// Creates an AppLogo widget
  const AppLogo({
    super.key,
    this.size = 24.0,
    this.color,
    this.useImage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useImage) {
      return Image.asset(
        AppAssets.logoPath,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            Icons.fitness_center,
            size: size,
            color: color,
          );
        },
      );
    } else {
      // Fallback to icon mode
      return Icon(
        Icons.fitness_center,
        size: size,
        color: color,
      );
    }
  }
}
