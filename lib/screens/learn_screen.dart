import 'dart:async';

import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../widgets/goal_celebrate_banner.dart';
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
    this.onLearnNew,
    this.onReviewWrongAll,
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
  /// Exit wrong-review and stay on 认读 (今日任务 · 学新词).
  final VoidCallback? onLearnNew;
  /// Enter whole-book wrong flashcards (今日任务 · 复习错词).
  final VoidCallback? onReviewWrongAll;

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
  bool _speaking = false;
  late final WordSpeaker _speaker;
  bool _ownsSpeaker = false;
  /// Quiet one-line hint under the unit picker (not a SnackBar).
  String? _unitFilterHint;
  Timer? _unitHintTimer;

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
          _error = '请先选择教材版本和年级';
        });
        return;
      }
      final book = await widget.repo.loadBook(id);
      if (book.words.isEmpty) {
        setState(() {
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

  Future<void> _flashThen(String kind, Future<void> Function() advance) async {
    setState(() => _flashKind = kind);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await advance();
    if (!mounted) return;
    setState(() => _flashKind = null);
  }

  Future<void> _onKnown() async {
    final q = _queue;
    final cur = q?.current;
    if (q == null || cur == null || _flashKind != null) return;
    await _flashThen('known', () async {
      final celebrate = await widget.store.markLearned(cur.id);
      setState(() {
        q.markKnown();
        _flipped = false;
      });
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

  int _unitWordCount() {
    final book = _book;
    if (book == null) return 0;
    final id = widget.bookId;
    final filter = id == null ? null : widget.store.unitFilterForBook(id);
    if (filter == null || filter.isEmpty) return book.words.length;
    return book.words.where((w) => w.unit == filter).length;
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
          const SnackBar(content: Text('暂时没法朗读')),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
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
              if (isEmptyDay && widget.onStartQuiz != null)
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
    final streak = widget.store.streakDays();
    final wrongCount = bookId == null ? 0 : widget.store.wrongCountForBook(bookId);
    final learnSub = '新词 $_queueNewCount · 复习 $_queueDueCount';
    final learnShowDot = !widget.reviewWrongOnly && _queueDueCount > 0;
    final wrongSub = wrongCount == 0 ? '暂无错词' : '$wrongCount 词';
    // 今日任务选中：全书错词复习 → 复习；否则默认学新词（自测走独立路由）
    final taskSelected = (widget.reviewWrongOnly && !widget.reviewWrongUnitScoped)
        ? _TodayTask.wrong
        : _TodayTask.learn;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.reviewWrongOnly
                  ? (widget.reviewWrongUnitScoped
                      ? '错词复习·当前单元 · ${_book?.title ?? ''}'
                      : '错词复习 · ${_book?.title ?? ''}')
                  : (_book?.title ?? ''),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _TodayTaskBar(
                todayLabel: '今日 $today/$goal · 连续 $streak 天',
                selected: taskSelected,
                learnSubtitle: learnSub,
                learnShowDot: learnShowDot,
                wrongSubtitle: wrongSub,
                wrongEnabled: wrongCount > 0,
                onLearn: () => widget.onLearnNew?.call(),
                onWrong: wrongCount > 0 ? () => widget.onReviewWrongAll?.call() : null,
                onQuiz: widget.onStartQuiz,
              ),
            ),
          ),
          if (!widget.reviewWrongOnly && widget.onStartQuiz != null) ...[
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'learn', label: Text('认读'), icon: Icon(Icons.style)),
                ButtonSegment(value: 'quiz', label: Text('自测'), icon: Icon(Icons.quiz_outlined)),
              ],
              selected: const {'learn'},
              onSelectionChanged: (s) {
                if (s.contains('quiz')) {
                  widget.onStartQuiz?.call();
                }
              },
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.reviewWrongOnly
                  ? '剩余 ${q.remaining} · 本轮认识 ${q.knownCount} · 本单元 ${_unitWordCount()}'
                  : '新词 $_queueNewCount · 复习 $_queueDueCount · 剩余 ${q.remaining}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if ((!widget.reviewWrongOnly || widget.reviewWrongUnitScoped) && units.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                key: const ValueKey('unit_picker_button'),
                avatar: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                label: Text(
                  selectedUnit == null || selectedUnit.isEmpty
                      ? '全部 · ${units.length} 单元 ▾'
                      : '$selectedUnit ▾',
                ),
                onPressed: () => _openUnitPicker(units: units, selectedUnit: selectedUnit),
              ),
            ),
            if (_unitFilterHint != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _unitFilterHint!,
                  key: const ValueKey('unit_filter_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? scheme.surfaceContainerHighest
                    : scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _flashKind == 'known'
                      ? scheme.primary
                      : (_flashKind == 'unknown' ? scheme.error : scheme.outlineVariant),
                  width: _flashKind != null ? 2 : 1,
                ),
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
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, anim) {
                              final scale = Tween<double>(begin: 0.98, end: 1).animate(anim);
                              return FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(scale: scale, child: child),
                              );
                            },
                            child: _flipped
                                ? Column(
                                    key: const ValueKey('back'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(word.meaning, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                      if ((word.example ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          word.example!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 16, height: 1.35),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Text('点按卡片可翻回', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('front'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(word.word, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                                      if (widget.store.learnedIds().contains(word.id)) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '复习',
                                          key: const ValueKey('review_tag'),
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                      if ((word.phonetic ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          word.phonetic!,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Text('点按卡片看中文', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PressScale(
                  child: OutlinedButton(
                    key: const ValueKey('learn_unknown'),
                    onPressed: _flashKind != null ? null : _onUnknown,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('不认识', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PressScale(
                  child: FilledButton(
                    key: const ValueKey('learn_known'),
                    onPressed: _flashKind != null ? null : _onKnown,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('认识', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}



enum _TodayTask { learn, wrong, quiz }

class _TodayTaskBar extends StatelessWidget {
  const _TodayTaskBar({
    required this.todayLabel,
    required this.selected,
    required this.learnSubtitle,
    this.learnShowDot = false,
    required this.wrongSubtitle,
    required this.wrongEnabled,
    required this.onLearn,
    required this.onWrong,
    required this.onQuiz,
  });

  final String todayLabel;
  final _TodayTask selected;
  final String learnSubtitle;
  final bool learnShowDot;
  final String wrongSubtitle;
  final bool wrongEnabled;
  final VoidCallback? onLearn;
  final VoidCallback? onWrong;
  final VoidCallback? onQuiz;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(todayLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TodayTaskButton(
                    key: const ValueKey('today_task_learn'),
                    title: '学新词',
                    subtitle: learnSubtitle,
                    icon: Icons.menu_book,
                    selected: selected == _TodayTask.learn,
                    showDot: learnShowDot,
                    onTap: onLearn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: wrongEnabled ? '复习本词书全部错词' : '暂无错词，先学新词或自测',
                    child: _TodayTaskButton(
                      key: const ValueKey('today_task_wrong'),
                      title: '复习错词',
                      subtitle: wrongSubtitle,
                      icon: Icons.replay,
                      selected: selected == _TodayTask.wrong,
                      onTap: onWrong,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TodayTaskButton(
                    key: const ValueKey('today_task_quiz'),
                    title: '自测',
                    subtitle: '测一测',
                    icon: Icons.quiz,
                    selected: selected == _TodayTask.quiz,
                    onTap: onQuiz,
                  ),
                ),
              ],
            ),
            if (!wrongEnabled) ...[
              const SizedBox(height: 6),
              Text(
                '暂无错词，先学新词或自测',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayTaskButton extends StatelessWidget {
  const _TodayTaskButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final bg = !enabled
        ? scheme.surface
        : (selected ? scheme.primaryContainer : scheme.surface);
    final titleColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (selected ? scheme.onPrimaryContainer : scheme.onSurface);
    final subColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
    final borderColor = !enabled
        ? scheme.outlineVariant.withValues(alpha: 0.4)
        : (selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4));
    final borderWidth = selected && enabled ? 2.0 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 24, color: titleColor),
                    if (showDot)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          key: const ValueKey('learn_due_dot'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 100;
                    return Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: wide ? 14 : 13,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    );
                  },
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
        ),
      ),
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

