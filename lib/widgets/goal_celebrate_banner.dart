import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _goalCelebrateEntry;
Timer? _goalCelebrateTimer;

/// Aligns with learn/quiz/me teal (R43–R49).
const Color celebrateTeal = Color(0xFF0D9488);

void _removeGoalCelebrate() {
  _goalCelebrateTimer?.cancel();
  _goalCelebrateTimer = null;
  _goalCelebrateEntry?.remove();
  _goalCelebrateEntry = null;
}

/// Non-modal top paper-card for daily goal met (R33 logic · R50 wow chrome).
/// Uses [Overlay] (not MaterialBanner) so the title is never height-clipped
/// beside AppBar / actions. Does not cover bottom dual CTAs.
void showGoalCelebratedBanner(
  BuildContext context, {
  required int count,
  required int goal,
  Duration autoHide = const Duration(seconds: 4),
}) {
  _removeGoalCelebrate();
  final scheme = Theme.of(context).colorScheme;
  final brightness = Theme.of(context).brightness;
  final paper = brightness == Brightness.dark
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainerLow;
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
          color: paper,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            key: const ValueKey('goal_celebrate_content'),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 22,
                      color: celebrateTeal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '今日目标达成 🌟',
                        key: const ValueKey('goal_celebrate_title'),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '已学 $count / $goal',
                  key: const ValueKey('goal_celebrate_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const ValueKey('goal_celebrate_continue'),
                    onPressed: _removeGoalCelebrate,
                    style: FilledButton.styleFrom(
                      backgroundColor: celebrateTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
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
