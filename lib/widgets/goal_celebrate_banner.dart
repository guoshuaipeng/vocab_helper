import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _goalCelebrateEntry;
Timer? _goalCelebrateTimer;

void _removeGoalCelebrate() {
  _goalCelebrateTimer?.cancel();
  _goalCelebrateTimer = null;
  _goalCelebrateEntry?.remove();
  _goalCelebrateEntry = null;
}

/// Non-modal top light-card for daily goal met (R33).
/// Uses [Overlay] (not MaterialBanner) so the title is never height-clipped
/// beside AppBar / actions.
void showGoalCelebratedBanner(
  BuildContext context, {
  required int count,
  required int goal,
  Duration autoHide = const Duration(seconds: 4),
}) {
  _removeGoalCelebrate();
  final scheme = Theme.of(context).colorScheme;
  final onC = scheme.onPrimaryContainer;
  final overlay = Overlay.of(context);

  _goalCelebrateEntry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.paddingOf(ctx).top + kToolbarHeight + 8;
      return Positioned(
        top: top,
        left: 12,
        right: 12,
        child: Material(
          key: const ValueKey('goal_celebrate_banner'),
          color: scheme.primaryContainer,
          elevation: 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            key: const ValueKey('goal_celebrate_content'),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '今日目标达成 🌟',
                  key: const ValueKey('goal_celebrate_title'),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: onC,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已学 $count / $goal',
                  key: const ValueKey('goal_celebrate_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: onC,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('goal_celebrate_continue'),
                    onPressed: _removeGoalCelebrate,
                    child: const Text('继续'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(_goalCelebrateEntry!);

  if (autoHide > Duration.zero) {
    _goalCelebrateTimer = Timer(autoHide, _removeGoalCelebrate);
  }
}
