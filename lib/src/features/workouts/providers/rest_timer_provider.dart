import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rest_timer_provider.freezed.dart';

@freezed
class RestTimerState with _$RestTimerState {
  const factory RestTimerState({
    @Default(false) bool isRunning,
    @Default(60) int totalDurationSeconds, // Default rest: 60 seconds
    @Default(0) int remainingSeconds,
  }) = _RestTimerState;
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(const RestTimerState());

  Timer? _timer;

  void startTimer({int? durationSeconds}) {
    _timer?.cancel(); // Cancel any existing timer

    final totalDuration = durationSeconds ?? state.totalDurationSeconds;
    state = state.copyWith(
      isRunning: true,
      totalDurationSeconds: totalDuration,
      remainingSeconds: totalDuration,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    } else {
      stopTimer();
      // TODO: Add notification/sound feedback?
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  final notifier = RestTimerNotifier();
  // Ensure timer is cancelled when the provider is disposed
  ref.onDispose(() {
    notifier.stopTimer();
  });
  return notifier;
});
