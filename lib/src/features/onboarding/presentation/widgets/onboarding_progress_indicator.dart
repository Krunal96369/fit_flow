import 'package:flutter/material.dart';

/// A widget that displays the user's progress through the onboarding flow
class OnboardingProgressIndicator extends StatelessWidget {
  /// The current step index (0-based)
  final int currentStep;

  /// The total number of steps
  final int totalSteps;

  /// Whether to display step numbers
  final bool showStepNumbers;

  /// Whether to animate progress changes
  final bool animate;

  /// Color for active steps
  final Color? activeColor;

  /// Color for inactive steps
  final Color? inactiveColor;

  /// Duration for the animation
  final Duration animationDuration;

  /// Constructor
  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.showStepNumbers = false,
    this.animate = true,
    this.activeColor,
    this.inactiveColor,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    // Use theme colors if not provided explicitly
    final Color effectiveActiveColor =
        activeColor ?? Theme.of(context).primaryColor;
    final Color effectiveInactiveColor =
        inactiveColor ?? Theme.of(context).disabledColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: LayoutBuilder(builder: (context, constraints) {
        // Calculate sizes based on available width and number of steps
        final double availableWidth =
            constraints.maxWidth - 24; // Add extra safety margin

        // Adjust sizes based on number of steps and available width
        // Make indicators smaller when there are more steps
        final double indicatorSize = totalSteps <= 4
            ? 26
            : totalSteps <= 6
                ? 20
                : 14;

        // Calculate spacing between elements to fit within available width
        final double totalIndicatorsWidth = indicatorSize * totalSteps;
        final double lineWidth = totalSteps > 1
            ? (availableWidth - totalIndicatorsWidth - 24) / (totalSteps - 1)
            : 0;

        // Limit line width to ensure it's not negative
        final double adjustedLineWidth = lineWidth > 0 ? lineWidth : 8;

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            constraints: BoxConstraints(maxWidth: availableWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalSteps, (index) {
                final isActive = index <= currentStep;
                final isDone = index < currentStep;

                // The step indicator (dot or number)
                Widget stepIndicator = _buildStepIndicator(
                    index,
                    isActive,
                    isDone,
                    indicatorSize,
                    effectiveActiveColor,
                    effectiveInactiveColor);

                // Add connecting line between indicators (except for the last one)
                if (index < totalSteps - 1) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      stepIndicator,
                      _buildConnectingLine(
                        isActive: index < currentStep,
                        nextActive: index + 1 <= currentStep,
                        width: adjustedLineWidth,
                        activeColor: effectiveActiveColor,
                        inactiveColor: effectiveInactiveColor,
                      ),
                    ],
                  );
                }

                return stepIndicator;
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepIndicator(int index, bool isActive, bool isDone, double size,
      Color activeColor, Color inactiveColor) {
    final color = isActive ? activeColor : inactiveColor;

    // Container that holds either a dot or a number
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.transparent,
        border: Border.all(
          color: color,
          width: 1.5,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? Icon(
                Icons.check,
                size: size * 0.6,
                color: Colors.white,
              )
            : showStepNumbers
                ? Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.5,
                    ),
                  )
                : null,
      ),
    );
  }

  Widget _buildConnectingLine({
    required bool isActive,
    required bool nextActive,
    required double width,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    // Determine the gradient colors based on the active state
    final startColor = isActive ? activeColor : inactiveColor;
    final endColor = nextActive ? activeColor : inactiveColor;

    return Container(
      width: width,
      height: 1.5, // Thinner line
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
        ),
      ),
    );
  }
}
