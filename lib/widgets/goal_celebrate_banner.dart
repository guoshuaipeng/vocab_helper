import 'dart:async';

import 'package:flutter/material.dart';

/// Non-modal once-per-cross MaterialBanner for daily goal met (R33).
void showGoalCelebratedBanner(
  BuildContext context, {
  required int count,
  required int goal,
  Duration autoHide = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentMaterialBanner();
  final scheme = Theme.of(context).colorScheme;
  messenger.showMaterialBanner(
    MaterialBanner(
      key: const ValueKey('goal_celebrate_banner'),
      backgroundColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      padding: const EdgeInsetsDirectional.only(start: 16, end: 8, top: 12, bottom: 8),
      content: Column(
        key: const ValueKey('goal_celebrate_content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '今日目标达成 🌟',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '已学 $count / $goal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('goal_celebrate_continue'),
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('继续'),
        ),
      ],
    ),
  );
  if (autoHide > Duration.zero) {
    Timer(autoHide, () {
      messenger.hideCurrentMaterialBanner();
    });
  }
}
