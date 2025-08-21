import 'package:flutter/material.dart';
import 'package:emotion_ai/core/theme/app_theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const GradientAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.onPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions ?? const [SizedBox(width: 40)],
          ),
        ],
      ),
    );
  }
}
