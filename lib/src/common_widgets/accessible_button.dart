import 'package:flutter/material.dart';

class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      child: ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}
