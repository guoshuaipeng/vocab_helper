import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMe(WidgetTester tester, {required FakeWordSpeaker speaker}) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
      'today_count': 1,
      'streak_days': 1,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            speaker: speaker,
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 16; i++) {
      if (find.text('朗读口音').evaluate().isNotEmpty) break;
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('无英文语音包时口音卡显示可行动提示', (tester) async {
    final speaker = FakeWordSpeaker()..voiceAvailable = false;
    await pumpMe(tester, speaker: speaker);
    expect(find.byKey(const ValueKey('me_accent_tts_hint')), findsOneWidget);
    final text = tester.widget<Text>(find.byKey(const ValueKey('me_accent_tts_hint'))).data ?? '';
    expect(text.contains('系统设置'), isTrue);
    expect(text.contains('语音'), isTrue);
  });

  testWidgets('有语音包时不显示缺包提示', (tester) async {
    final speaker = FakeWordSpeaker()..voiceAvailable = true;
    await pumpMe(tester, speaker: speaker);
    expect(find.byKey(const ValueKey('me_accent_tts_hint')), findsNothing);
  });
}
