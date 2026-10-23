import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expand 「更多设置」 so nested keys (export / unit / accent / stats) are hittable.
/// ListView parks the tile below the fold — use skipOffstage: false to find it.
Future<void> expandMeMore(WidgetTester tester) async {
  final more = find.byKey(const ValueKey('me_more_section'), skipOffstage: false);
  for (var i = 0; i < 30 && more.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(more, findsOneWidget);

  final export = find.byKey(const ValueKey('export_progress'), skipOffstage: false);
  if (export.evaluate().isNotEmpty) {
    try {
      if (tester.getSize(export).height > 1) return;
    } catch (_) {}
  }

  final scrollables = find.byType(Scrollable);
  expect(scrollables, findsWidgets);
  await tester.scrollUntilVisible(more, 150, scrollable: scrollables.first);
  await tester.pump(const Duration(milliseconds: 120));

  final title = find.descendant(
    of: find.byKey(const ValueKey('me_more_section')),
    matching: find.text('更多设置'),
  );
  final target = title.evaluate().isNotEmpty
      ? title
      : find.byKey(const ValueKey('me_more_section'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}
