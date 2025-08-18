import 'package:flutter/material.dart';
import 'package:emotion_ai/core/theme/app_theme.dart';

class PrimaryGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const PrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.primaryGradientDecoration,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
