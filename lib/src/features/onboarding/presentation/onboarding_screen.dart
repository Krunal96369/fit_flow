import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/accessible_button.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _completeOnboarding(ref),
                child: const Text('Skip'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Welcome to FitFlow!\nOnboarding screens coming soon...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AccessibleButton(
                onPressed: () => _completeOnboarding(ref),
                semanticLabel: 'Complete onboarding',
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeOnboarding(WidgetRef ref) {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
  }
}
