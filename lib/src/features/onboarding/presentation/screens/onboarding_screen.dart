import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_controller.dart';
import '../../application/onboarding_to_profile_service.dart';
import '../../domain/models/onboarding_step.dart';
import '../widgets/onboarding_progress_indicator.dart';
import 'onboarding_steps/completion_step.dart';
import 'onboarding_steps/feature_tour_step.dart';
import 'onboarding_steps/goal_setting_step.dart';
import 'onboarding_steps/permissions_step.dart';
import 'onboarding_steps/profile_setup_step.dart';
import 'onboarding_steps/welcome_step.dart';

/// Main screen for the onboarding process
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Constructor
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStepIndex = ref.watch(currentStepIndexProvider);
    final stepsAsync = ref.watch(onboardingStepsProvider);

    // Listen for changes to current step index and animate the page view
    ref.listen<int>(currentStepIndexProvider, (previous, current) {
      if (previous != current && _pageController.hasClients) {
        _pageController.animateToPage(
          current,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: stepsAsync.when(
          data: (steps) =>
              _buildOnboardingContent(context, steps, currentStepIndex),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading onboarding: $error'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(onboardingStepsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(
    BuildContext context,
    List<OnboardingStep> steps,
    int currentStepIndex,
  ) {
    return Column(
      children: [
        // Skip button - only show on first few screens
        if (currentStepIndex < steps.length - 1)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text('Skip'),
              ),
            ),
          ),

        // Main content - PageView with step screens
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            itemCount: steps.length,
            onPageChanged: (index) {
              // Update the current step index in the provider
              ref.read(currentStepIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                child: _buildStepContent(steps[index]),
              );
            },
          ),
        ),

        // Progress indicator and navigation buttons
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              OnboardingProgressIndicator(
                currentStep: currentStepIndex,
                totalSteps: steps.length,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),

              const SizedBox(height: 24),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button - only show if not on first screen
                  if (currentStepIndex > 0)
                    TextButton(
                      onPressed: _goToPreviousStep,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),

                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _goToNextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      currentStepIndex == steps.length - 1 ? 'Finish' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    // Return the appropriate step widget based on the step ID
    switch (step.id) {
      case 'welcome':
        return const WelcomeStep();
      case 'profile_setup':
        return const ProfileSetupStep();
      case 'goal_setting':
        return const GoalSettingStep();
      case 'feature_tour':
        return const FeatureTourStep();
      case 'permissions':
        return const PermissionsStep();
      case 'completion':
        return const CompletionStep();
      default:
        return Center(
          child: Text('Unknown step: ${step.id}'),
        );
    }
  }

  // Updated implementation to save data using the providers
  void _goToNextStep() async {
    // First, get the current state
    final currentIndex = ref.read(currentStepIndexProvider);
    final stepsAsync = ref.watch(onboardingStepsProvider);

    // Try to get steps data
    if (stepsAsync.hasValue) {
      final steps = stepsAsync.value!;
      final currentStep = steps[currentIndex];

      // Get the profile service
      final profileService = ref.read(onboardingToProfileServiceProvider);

      if (currentStep.id == 'profile_setup') {
        // Get profile data from the provider
        final profileData = ref.read(profileFormProvider);

        // Save profile data to Firebase
        try {
          await profileService.saveProfileData(
            displayName: profileData.displayName,
            gender: profileData.gender,
            dateOfBirth: profileData.dateOfBirth,
            height: profileData.height,
            weight: profileData.weight,
            heightUnit: profileData.heightUnit,
            weightUnit: profileData.weightUnit,
          );
          debugPrint('Successfully saved profile data from provider');
        } catch (e) {
          debugPrint('Error saving profile data: $e');
        }
      } else if (currentStep.id == 'goal_setting') {
        // Get fitness goals from the provider
        final goalsData = ref.read(fitnessGoalsProvider);

        // Save fitness goals to Firebase
        try {
          await profileService.saveFitnessGoals(
            primaryGoal: goalsData.primaryGoal,
            workoutsPerWeek: goalsData.workoutsPerWeek,
          );
          debugPrint('Successfully saved fitness goals from provider');
        } catch (e) {
          debugPrint('Error saving fitness goals: $e');
        }
      }
    }

    // Proceed to next step
    ref.read(onboardingControllerProvider.notifier).goToNextStep();
  }

  void _goToPreviousStep() {
    final currentIndex = ref.read(currentStepIndexProvider);
    if (currentIndex > 0) {
      ref.read(currentStepIndexProvider.notifier).state = currentIndex - 1;
    }
  }

  void _skipOnboarding() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'Are you sure you want to skip the onboarding process? '
          'You can always access it later from your profile settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(onboardingCompletedProvider.notifier)
                  .completeOnboarding();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
