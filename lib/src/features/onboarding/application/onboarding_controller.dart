import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage_service.dart';

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
      final localStorageService = ref.watch(localStorageServiceProvider);
      return OnboardingNotifier(localStorageService);
    });

class OnboardingNotifier extends StateNotifier<bool> {
  final LocalStorageService _localStorageService;
  static const String _onboardingKey = 'onboarding_completed';

  OnboardingNotifier(this._localStorageService) : super(false) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final completed =
        await _localStorageService.getData<bool>(
          'preferences',
          _onboardingKey,
        ) ??
        false;
    state = completed;
  }

  Future<void> completeOnboarding() async {
    state = true;
    await _localStorageService.saveData('preferences', _onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    state = false;
    await _localStorageService.saveData('preferences', _onboardingKey, false);
  }
}
