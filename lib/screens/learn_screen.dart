import 'dart:async';

import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../widgets/goal_celebrate_banner.dart';
import '../widgets/friendly_thumb.dart';
import '../services/wordbook_repository.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.bookId,
    required this.onNeedSetup,
    this.reviewWrongOnly = false,
    this.reviewWrongUnitScoped = false,
    this.speaker,
    this.onStartQuiz,
    this.onQuizWrong,
    this.onLearnNew,
    this.onReviewWrongAll,
    this.onChangeBook,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String? bookId;
  final VoidCallback onNeedSetup;
  final bool reviewWrongOnly;
  /// When [reviewWrongOnly], limit to ProgressStore unit filter (same as learn).
  final bool reviewWrongUnitScoped;
  final WordSpeaker? speaker;
  final VoidCallback? onStartQuiz;
  /// R46: from wrong-review done → QuizMode.wrong.
  final VoidCallback? onQuizWrong;
  /// Exit wrong-review and stay on 认读 (今日任务 · 学新词).
  final VoidCallback? onLearnNew;
  /// Enter whole-book wrong flashcards (今日任务 · 复习错词).
  final VoidCallback? onReviewWrongAll;
  /// R42: open换书 (Setup/Books path).
  final VoidCallback? onChangeBook;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ReviewQueue? _queue;
  WordBook? _book;
  bool _flipped = false;
  bool _loading = true;
  String? _error;
  int _queueNewCount = 0;
  int _queueDueCount = 0;
  /// null | known | unknown — brief edge flash before advancing.
  String? _flashKind;
  /// Horizontal slide for answer exit: +1 known / -1 unknown.
  double _slideX = 0;
  bool _speaking = false;
  late final WordSpeaker _speaker;
  bool _ownsSpeaker = false;
  /// Quiet one-line hint under the unit picker (not a SnackBar).
  String? _unitFilterHint;
  Timer? _unitHintTimer;

  /// R38: quiet "下次 · …" after 认识 (not a SnackBar).
  String? _reviewNextHint;
  Timer? _reviewNextHintTimer;

  /// R42: catalog contains recommended follow-along book.
  bool _catalogHasRecommended = false;

  @override
  void initState() {
    super.initState();
    if (widget.speaker != null) {
      _speaker = widget.speaker!;
    } else {
      _speaker = FlutterWordSpeaker(languageCode: widget.store.ttsAccent());
      _ownsSpeaker = true;
    }
    _boot();
  }

  @override
  void dispose() {
    _unitHintTimer?.cancel();
    _reviewNextHintTimer?.cancel();
    if (_ownsSpeaker) {
      _speaker.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.reviewWrongOnly != widget.reviewWrongOnly ||
        oldWidget.reviewWrongUnitScoped != widget.reviewWrongUnitScoped) {
      _boot();
    }
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.bookId;
      if (id == null || id.isEmpty) {
        setState(() {
          _loading = false;
          _catalogHasRecommended = false;
          _error = '请先选择教材版本和年级';
        });
        return;
      }
      final catalog = await widget.repo.loadCatalog();
      final hasRec = catalog.any((b) => b.id == WordbookRepository.recommendedBookId);
      final book = await widget.repo.loadBook(id);
      if (book.words.isEmpty) {
        setState(() {
          _catalogHasRecommended = hasRec;
          _loading = false;
          _error = '这本词书还没有单词';
        });
        return;
      }
      final unitFilter = widget.store.unitFilterForBook(id);
      final applyUnit = !widget.reviewWrongOnly || widget.reviewWrongUnitScoped;
      var scoped = book.words;
      if (applyUnit && unitFilter != null && unitFilter.isNotEmpty) {
        scoped = book.words.where((w) => w.unit == unitFilter).toList();
      }

      List<Word> list;
      if (widget.reviewWrongOnly) {
        list = filterWrongWords(
          words: book.words,
          wrongIds: widget.store.wrongIds(),
          unitFilter: widget.reviewWrongUnitScoped ? unitFilter : null,
        );
        if (list.isEmpty) {
          setState(() {
            _book = book;
            _queue = ReviewQueue(list);
            _catalogHasRecommended = hasRec;
            _flipped = false;
            _loading = false;
            _error = widget.reviewWrongUnitScoped && unitFilter != null && unitFilter.isNotEmpty
                ? '当前单元没有错词，可换单元或复习全部错词'
                : '错词本是空的，先在学习里点「不认识」吧';
          });
          return;
        }
      } else {
        if (scoped.isEmpty) {
          setState(() {
            _book = book;
            _queue = ReviewQueue(const []);
            _queueNewCount = 0;
            _queueDueCount = 0;
            _catalogHasRecommended = hasRec;
            _flipped = false;
            _loading = false;
            _error = '这个单元暂时没有单词';
          });
          return;
        }
        final learned = widget.store.learnedIds();
        final due = <Word>[];
        final fresh = <Word>[];
        for (final w in scoped) {
          if (!learned.contains(w.id)) {
            fresh.add(w);
          } else if (widget.store.isReviewDue(w.id)) {
            due.add(w);
          }
        }
        due.sort((a, b) {
          final aa = widget.store.reviewAt(a.id) ?? '';
          final bb = widget.store.reviewAt(b.id) ?? '';
          return aa.compareTo(bb);
        });
        list = [...due, ...fresh];
        _queueDueCount = due.length;
        _queueNewCount = fresh.length;
      }
      await widget.store.touchActive();
      setState(() {
        _book = book;
        _queue = ReviewQueue(list);
        if (widget.reviewWrongOnly) {
          _queueNewCount = 0;
          _queueDueCount = 0;
        }
        _catalogHasRecommended = hasRec;
        _flipped = false;
        _loading = false;
      });
      await _maybeAutoSpeak();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }


  void _showReviewNextHint(String msg) {
    if (!widget.store.reviewNextHintEnabled()) return;
    _reviewNextHintTimer?.cancel();
    setState(() => _reviewNextHint = msg);
    _reviewNextHintTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_reviewNextHint == msg) setState(() => _reviewNextHint = null);
    });
  }

  Future<void> _flashThen(String kind, Future<void> Function() advance) async {
    setState(() {
      _flashKind = kind;
      _slideX = kind == 'known' ? 1.0 : -1.0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await advance();
    if (!mounted) return;
    setState(() {
      _flashKind = null;
      _slideX = 0;
    });
  }

  Future<void> _onKnown() async {
    final q = _queue;
    final cur = q?.current;
    if (q == null || cur == null || _flashKind != null) return;
    await _flashThen('known', () async {
      final celebrate = await widget.store.markLearned(cur.id);
      final stage = widget.store.reviewStage(cur.id) ?? 0;
      setState(() {
        q.markKnown();
        _flipped = false;
      });
      if (mounted) {
        _showReviewNextHint(ProgressStore.nextReviewHintForStage(stage));
      }
      if (celebrate && mounted) {
        showGoalCelebratedBanner(
          context,
          count: widget.store.todayCount(),
          goal: widget.store.dailyGoal(),
        );
      }
      await _maybeAutoSpeak();
    });
  }

  Future<void> _onUnknown() async {
    final q = _queue;
    final cur = q?.current;
    if (q == null || cur == null || _flashKind != null) return;
    await _flashThen('unknown', () async {
      await widget.store.markWrong(cur.id);
      setState(() {
        q.markUnknown();
        _flipped = false;
      });
      await _maybeAutoSpeak();
    });
  }


  Future<void> _pickUnit(String? unit) async {
    final id = widget.bookId;
    if (id == null) return;
    await widget.store.setUnitFilterForBook(id, unit);
    await _boot();
    if (!mounted) return;
    final msg = (unit == null || unit.isEmpty) ? '显示全部' : '已筛选 · $unit';
    _unitHintTimer?.cancel();
    setState(() => _unitFilterHint = msg);
    _unitHintTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_unitFilterHint == msg) setState(() => _unitFilterHint = null);
    });
  }

  Future<void> _openUnitPicker({
    required List<String> units,
    required String? selectedUnit,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _UnitPickerSheet(
          units: units,
          selectedUnit: selectedUnit,
        );
      },
    );
    if (!mounted || picked == null) return; // dismissed without choice
    await _pickUnit(picked == _UnitPickerSheet.allSentinel ? null : picked);
  }

  Future<void> _maybeAutoSpeak() async {
    if (!widget.store.autoSpeak()) return;
    await _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    final word = _queue?.current;
    if (word == null || _speaking) return;
    setState(() => _speaking = true);
    try {
      await _speaker.setAccent(widget.store.ttsAccent());
      await _speaker.speak(word.word);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('暂时没法朗读'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 88),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  bool get _shouldShowLearnRecommendHint {
    final id = widget.bookId;
    if (id == null || id.isEmpty) return false;
    if (!_catalogHasRecommended) return false;
    if (id == WordbookRepository.recommendedBookId) return false;
    if (widget.onChangeBook == null) return false;
    if (widget.store.isRecommendHintHiddenToday()) return false;
    return true;
  }

  Future<void> _dismissRecommendHint() async {
    await widget.store.dismissRecommendHintForToday();
    if (mounted) setState(() {});
  }


  Future<void> _openMorePractice({
    required List<String> units,
    required String? selectedUnit,
    required int wrongCount,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text('更多练习', style: Theme.of(ctx).textTheme.titleLarge),
                ),
                // R48 B04: 选择单元置顶，跟课换单元首屏可见
                if ((!widget.reviewWrongOnly || widget.reviewWrongUnitScoped) && units.isNotEmpty)
                  ListTile(
                    key: const ValueKey('unit_picker_button'),
                    leading: Icon(
                      Icons.filter_list,
                      color: (selectedUnit != null && selectedUnit.isNotEmpty)
                          ? const Color(0xFF0D9488)
                          : null,
                    ),
                    title: const Text('选择单元'),
                    subtitle: Text(
                      selectedUnit == null || selectedUnit.isEmpty
                          ? '全部 · ${units.length} 单元'
                          : selectedUnit,
                    ),
                    trailing: (selectedUnit != null && selectedUnit.isNotEmpty)
                        ? const Icon(Icons.check, color: Color(0xFF0D9488))
                        : null,
                    onTap: () => Navigator.pop(ctx, 'unit'),
                  ),
                ListTile(
                  key: const ValueKey('today_task_learn'),
                  leading: const Icon(Icons.menu_book),
                  title: const Text('学新词'),
                  subtitle: Text('新词 $_queueNewCount · 复习 $_queueDueCount'),
                  onTap: () => Navigator.pop(ctx, 'learn'),
                ),
                ListTile(
                  key: const ValueKey('today_task_wrong'),
                  leading: const Icon(Icons.replay),
                  title: const Text('复习错词'),
                  subtitle: Text(wrongCount == 0 ? '暂无错词' : '$wrongCount 词'),
                  enabled: wrongCount > 0 && widget.onReviewWrongAll != null,
                  onTap: wrongCount > 0 ? () => Navigator.pop(ctx, 'wrong') : null,
                ),
                ListTile(
                  key: const ValueKey('today_task_quiz'),
                  leading: const Icon(Icons.quiz),
                  title: const Text('自测'),
                  enabled: widget.onStartQuiz != null,
                  onTap: widget.onStartQuiz != null ? () => Navigator.pop(ctx, 'quiz') : null,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'learn') {
      widget.onLearnNew?.call();
    } else if (action == 'wrong') {
      widget.onReviewWrongAll?.call();
    } else if (action == 'quiz') {
      widget.onStartQuiz?.call();
    } else if (action == 'unit') {
      await _openUnitPicker(units: units, selectedUnit: selectedUnit);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final err = _error!;
      final needSetup = err.contains('请先选择');
      final wrongEmpty = widget.reviewWrongOnly && err.contains('错词');
      final unitEmpty = err.contains('这个单元暂时没有单词');
      final loadFail = err.startsWith('加载失败');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(err, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (needSetup)
                FilledButton(onPressed: widget.onNeedSetup, child: const Text('去选择年级'))
              else if (wrongEmpty && widget.onLearnNew != null)
                FilledButton(onPressed: widget.onLearnNew, child: const Text('去学新词'))
              else if (unitEmpty)
                FilledButton(onPressed: () => _pickUnit(null), child: const Text('看全部'))
              else if (loadFail)
                FilledButton(onPressed: _boot, child: const Text('重试'))
              else
                FilledButton(onPressed: widget.onNeedSetup, child: const Text('去选择年级')),
              if (!loadFail) TextButton(onPressed: _boot, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final q = _queue!;
    final word = q.current;
    if (word == null) {
      final isEmptyDay = !widget.reviewWrongOnly && q.knownCount == 0;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.reviewWrongOnly
                    ? '错词本本轮复习完啦！'
                    : (isEmptyDay ? '今天没有新词和到期复习' : '本轮单词都过完啦！'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                isEmptyDay ? '去自测一下，或明天再来认读。' : '本轮认识 ${q.knownCount} 个，棒！',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.reviewWrongOnly && widget.onQuizWrong != null)
                FilledButton(
                  key: const ValueKey('learn_wrong_done_quiz'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.onQuizWrong,
                  child: const Text('测这些错词'),
                )
              else if (isEmptyDay && widget.onStartQuiz != null)
                FilledButton(onPressed: widget.onStartQuiz, child: const Text('去自测一下'))
              else
                FilledButton(onPressed: _boot, child: const Text('再来一轮')),
              if (widget.reviewWrongOnly && widget.onLearnNew != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: widget.onLearnNew, child: const Text('去学新词')),
              ],
            ],
          ),
        ),
      );
    }

    final bookId = widget.bookId;
    final selectedUnit = bookId == null ? null : widget.store.unitFilterForBook(bookId);
    final units = _book?.unitNames() ?? const <String>[];

    final today = widget.store.todayCount();
    final goal = widget.store.dailyGoal();
    final wrongCount = bookId == null ? 0 : widget.store.wrongCountForBook(bookId);
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;
    final isLandscape = media.orientation == Orientation.landscape;
    // Teal CTA (design lock); seed stays #4F8CFF — not purple.
    const knowTeal = Color(0xFF0D9488);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700 || (isLandscape && constraints.maxWidth >= 600);
        final contentMax = wide ? (shortest >= 600 ? 960.0 : 900.0) : 520.0;
        final hPad = wide ? 28.0 : 16.0;
        final vPad = wide ? 12.0 : 8.0;
        final wordSize = wide ? 56.0 : 48.0;
        final meaningSize = wide ? 28.0 : 24.0;
        final progress = goal <= 0 ? 0.0 : (today / goal).clamp(0.0, 1.0);
        final bodyH = constraints.maxHeight;
        final ctaMinH = bodyH * 0.18;
        final meaningText = (word.meaning).trim().isEmpty ? '暂无释义' : word.meaning;

        Widget thinChrome() {
          return Column(
            key: const ValueKey('learn_progress_thin'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          () {
                            final parts = <String>['今日 $today/$goal'];
                            final title = _book?.title;
                            if (title != null && title.isNotEmpty) parts.add(title);
                            // R48: persistent unit in thin chrome when filtered
                            if (selectedUnit != null && selectedUnit.isNotEmpty) {
                              parts.add(selectedUnit);
                            }
                            return parts.join(' · ');
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('learn_overflow_menu'),
                    tooltip: '更多练习',
                    onPressed: () => _openMorePractice(
                      units: units,
                      selectedUnit: selectedUnit,
                      wrongCount: wrongCount,
                    ),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              if (_shouldShowLearnRecommendHint) ...[
                const SizedBox(height: 4),
                Material(
                  key: const ValueKey('learn_recommend_switch_hint'),
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: widget.onChangeBook,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: scheme.onSecondaryContainer,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                '跟课推荐 · 去切换',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('learn_recommend_hint_dismiss'),
                          onPressed: _dismissRecommendHint,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: scheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            '今日不再',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_unitFilterHint != null) ...[
                const SizedBox(height: 2),
                Text(
                  _unitFilterHint!,
                  key: const ValueKey('unit_filter_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_reviewNextHint != null) ...[
                const SizedBox(height: 2),
                Text(
                  _reviewNextHint!,
                  key: const ValueKey('review_next_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        }

        Widget flashCard() {
          final paper = Theme.of(context).brightness == Brightness.dark
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerLow;
          return AnimatedSlide(
            offset: Offset(_slideX, 0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _slideX == 0 ? 1 : 0.15,
              duration: const Duration(milliseconds: 250),
              child: AnimatedContainer(
                key: const ValueKey('learn_flash_card'),
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _flashKind == 'known'
                        ? knowTeal
                        : (_flashKind == 'unknown' ? scheme.error : scheme.outlineVariant.withValues(alpha: 0.45)),
                    width: _flashKind != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        key: const ValueKey('flashcard_speak'),
                        tooltip: '朗读',
                        onPressed: _speaking ? null : _speakCurrent,
                        icon: Icon(
                          Icons.volume_up,
                          color: _speaking ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _flipped = !_flipped),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(wide ? 36 : 24, 0, wide ? 36 : 24, 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  word.word,
                                  key: const ValueKey('learn_wow_word'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: wordSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                  ),
                                ),
                                if (widget.store.learnedIds().contains(word.id)) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '复习',
                                    key: const ValueKey('review_tag'),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: scheme.primary,
                                        ),
                                  ),
                                ],
                                if ((word.phonetic ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    word.phonetic!,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: _flipped
                                      ? Column(
                                          key: const ValueKey('back'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              meaningText,
                                              key: const ValueKey('learn_wow_meaning'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: meaningSize,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if ((word.example ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                word.example!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 15, height: 1.35),
                                              ),
                                            ],
                                          ],
                                        )
                                      : Container(
                                          key: const ValueKey('learn_wow_reveal_hint'),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: scheme.surface.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: scheme.outlineVariant.withValues(alpha: 0.9),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            '· · ·  点按看中文  · · ·',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: scheme.onSurfaceVariant,
                                                  letterSpacing: 0.2,
                                                ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        Widget ctaRow({required bool vertical}) {
          // Large bare thumbs (no pill/circle). 认识: elastic stretch-out + settle.
          final iconSize = vertical ? 72.0 : 64.0;
          final unknown = _PressScale(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('learn_unknown'),
                onTap: _flashKind != null ? null : _onUnknown,
                borderRadius: BorderRadius.circular(20),
                splashColor: scheme.onSurface.withValues(alpha: 0.08),
                child: Opacity(
                  opacity: _flashKind != null ? 0.4 : 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: vertical ? 12 : 8,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FriendlyThumb(
                          color: scheme.onSurfaceVariant,
                          size: iconSize,
                          down: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '不认识',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          final known = ElasticKnownThumbCta(
            key: const ValueKey('learn_known'),
            enabled: _flashKind == null,
            vertical: vertical,
            iconSize: iconSize,
            color: knowTeal,
            label: '认识',
            onAction: _onKnown,
          );
          if (vertical) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: known),
                const SizedBox(height: 12),
                Expanded(child: unknown),
              ],
            );
          }
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: ctaMinH.clamp(88.0, 140.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: unknown),
                const SizedBox(width: 8),
                Expanded(child: known),
              ],
            ),
          );
        }


        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + 4),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  thinChrome(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: flashCard()),
                              const SizedBox(width: 16),
                              SizedBox(width: 176, child: ctaRow(vertical: true)),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 55, child: flashCard()),
                              const SizedBox(height: 12),
                              Flexible(
                                flex: 18,
                                fit: FlexFit.loose,
                                child: ctaRow(vertical: false),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


/// Press feedback: scale to 0.98 for ~150ms (P2 learn-scale).
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}


class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({
    required this.units,
    required this.selectedUnit,
  });

  /// Pop value for「全部」(clears filter). Barrier dismiss returns null.
  static const allSentinel = '__all__';

  final List<String> units;
  final String? selectedUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.55;
    final selected = selectedUnit;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text('选择单元', style: Theme.of(context).textTheme.titleLarge),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: ListView(
                key: const ValueKey('unit_picker_list'),
                shrinkWrap: true,
                children: [
                  ListTile(
                    key: const ValueKey('unit_picker_all'),
                    title: const Text('全部'),
                    subtitle: Text('共 ${units.length} 个单元'),
                    trailing: (selected == null || selected.isEmpty)
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    selected: selected == null || selected.isEmpty,
                    onTap: () => Navigator.pop(context, allSentinel),
                  ),
                  const Divider(height: 1),
                  ...units.map((u) {
                    final isSel = selected == u;
                    return ListTile(
                      key: ValueKey('unit_picker_row_$u'),
                      title: Text(u),
                      trailing: isSel ? Icon(Icons.check, color: scheme.primary) : null,
                      selected: isSel,
                      onTap: () => Navigator.pop(context, u),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

