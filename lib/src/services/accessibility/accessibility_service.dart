import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final textScaleFactorProvider =
    StateNotifierProvider<TextScaleFactorNotifier, double>((ref) {
      return TextScaleFactorNotifier();
    });

final reducedMotionProvider =
    StateNotifierProvider<ReducedMotionNotifier, bool>((ref) {
      return ReducedMotionNotifier();
    });

class TextScaleFactorNotifier extends StateNotifier<double> {
  static const String _textScaleKey = 'text_scale_factor';

  TextScaleFactorNotifier() : super(1.0) {
    _loadTextScale();
  }

  Future<void> _loadTextScale() async {
    final box = await Hive.openBox<dynamic>('preferences');
    final savedScale = box.get(_textScaleKey) as double?;
    if (savedScale != null) {
      state = savedScale;
    }
  }

  Future<void> setTextScaleFactor(double scale) async {
    state = scale;
    final box = await Hive.openBox<dynamic>('preferences');
    await box.put(_textScaleKey, scale);
  }
}

class ReducedMotionNotifier extends StateNotifier<bool> {
  static const String _reducedMotionKey = 'reduced_motion';

  ReducedMotionNotifier() : super(false) {
    _loadReducedMotion();
  }

  Future<void> _loadReducedMotion() async {
    final box = await Hive.openBox<dynamic>('preferences');
    final savedValue = box.get(_reducedMotionKey) as bool?;
    if (savedValue != null) {
      state = savedValue;
    }
  }

  Future<void> setReducedMotion(bool value) async {
    state = value;
    final box = await Hive.openBox<dynamic>('preferences');
    await box.put(_reducedMotionKey, value);
  }
}

// Helper function to determine if animations should be displayed
bool shouldShowAnimations(WidgetRef ref) {
  return !ref.watch(reducedMotionProvider);
}
