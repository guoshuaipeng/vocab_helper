import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/quiz_engine.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../services/wordbook_repository.dart';
import '../widgets/goal_celebrate_banner.dart';

enum QuizMode {
  /// Whole selected book.
  book,
  /// Current unit filter (falls back to book if none).
  unit,
  /// Wrong-book words.
  wrong,
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.mode,
    this.wrongUnitScoped = false,
    this.speaker,
    this.seedQuestions,
    this.seedBookTitle,
    this.embedded = false,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final QuizMode mode;
  final bool wrongUnitScoped;
  final WordSpeaker? speaker;
  final List<QuizQuestion>? seedQuestions;
  final String? seedBookTitle;
  /// When true, omit Scaffold/AppBar (embed under LearnScreen).
  final bool embedded;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = true;
  String? _error;
  WordBook? _book;
  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  late final WordSpeaker _speaker;
  bool _ownsSpeaker = false;
  /// Effective variant: meaning | word | listen | spell | dictation.
  String _variant = 'meaning';
  bool _listenAvailable = true;
  /// After TTS failure, force meaning for the rest of the round.
  bool _forceMeaning = false;
  final TextEditingController _spellCtrl = TextEditingController();
  final FocusNode _spellFocus = FocusNode();
  /// null until checked; true/false after grade.
  bool? _spellOk;
  /// R32: quiz pool = wrong words only (respects unit when mode/unit filter).
  bool _poolWrongOnly = false;
  int _wrongInScope = 0;
  /// R35: this-round wrong word ids (first-wrong order; correct removes).
  List<String> _sessionWrongIds = [];
  /// R35: currently in a wrong-retry round (variant locked).
  bool _retryRound = false;

  @override
  void initState() {
    super.initState();
    if (widget.speaker != null) {
      _speaker = widget.speaker!;
    } else {
      _speaker = FlutterWordSpeaker(languageCode: widget.store.ttsAccent());
      _ownsSpeaker = true;
    }
    _variant = widget.store.quizVariant();
    _poolWrongOnly = widget.mode == QuizMode.wrong;
    _prepareAndBoot();
  }

  Future<void> _prepareAndBoot() async {
    _listenAvailable = await _speaker.englishVoiceAvailable();
    if (!_listenAvailable && (_variant == 'listen' || _variant == 'dictation')) {
      _variant = 'meaning';
    }
    if (_forceMeaning) _variant = 'meaning';
    await _boot();
  }

  @override
  void dispose() {
    _spellCtrl.dispose();
    _spellFocus.dispose();
    if (_ownsSpeaker) {
      _speaker.dispose();
    }
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (widget.seedQuestions != null) {
      setState(() {
        _book = null;
        _questions = widget.seedQuestions!;
        _index = 0;
        _selected = null;
        _answered = false;
        _spellOk = null;
        _spellCtrl.clear();
        _correctCount = 0;
        _wrongCount = 0;
        _sessionWrongIds = [];
        _retryRound = false;
        _loading = false;
        _error = widget.seedQuestions!.isEmpty ? '无法生成题目' : null;
      });
      if (widget.seedQuestions!.isNotEmpty) {
        await _speakCurrentIfListen();
      }
      return;
    }

    try {
      final id = widget.store.selectedBookId();
      if (id == null || id.isEmpty) {
        setState(() {
          _loading = false;
          _error = '请先选择教材';
        });
        return;
      }
      final book = (await widget.repo.loadBook(id)).withUnits();
      if (book.words.length < 2) {
        setState(() {
          _loading = false;
          _error = '词书单词太少，无法出题';
        });
        return;
      }

      final unitFilter = widget.store.unitFilterForBook(id);
      if (widget.mode == QuizMode.unit && (unitFilter == null || unitFilter.isEmpty)) {
        setState(() {
          _book = book;
          _loading = false;
          _error = '请先在学习页选择一个单元，再自测当前单元';
        });
        return;
      }

      final wrongIds = widget.store.wrongIds();
      final String? scopeUnit = switch (widget.mode) {
        QuizMode.unit => unitFilter,
        QuizMode.wrong => widget.wrongUnitScoped ? unitFilter : null,
        QuizMode.book => null,
      };

      final wrongInScope = buildQuizPool(
        bookWords: book.words,
        wrongIds: wrongIds,
        unitFilter: scopeUnit,
        wrongOnly: true,
      ).length;

      // book/unit: chip controls; wrong mode: starts wrong-only, chip can clear.
      final useWrong = _poolWrongOnly;

      final pool = buildQuizPool(
        bookWords: book.words,
        wrongIds: wrongIds,
        unitFilter: scopeUnit,
        wrongOnly: useWrong,
      );

      if (pool.isEmpty) {
        setState(() {
          _book = book;
          _wrongInScope = wrongInScope;
          _loading = false;
          if (useWrong) {
            _error = (scopeUnit ?? '').isNotEmpty ? '本单元没有错词' : '还没有错词，先去学或自测';
          } else if (widget.mode == QuizMode.unit) {
            _error = '这个单元暂时没有单词';
          } else {
            _error = '无法生成题目';
          }
        });
        return;
      }

      final session = QuizEngine.buildSession(
        pool: pool,
        bookWords: book.words,
        dailyGoal: widget.store.dailyGoal(),
        listenMode: _usesMeaningOptions,
      );
      if (session.isEmpty) {
        setState(() {
          _book = book;
          _loading = false;
          _error = '无法生成题目（干扰项不足）';
        });
        return;
      }

      setState(() {
        _book = book;
        _questions = session;
        _index = 0;
        _selected = null;
        _answered = false;
        _spellOk = null;
        _spellCtrl.clear();
        _correctCount = 0;
        _wrongCount = 0;
        _sessionWrongIds = [];
        _retryRound = false;
        _wrongInScope = wrongInScope;
        _loading = false;
      });
      await _speakCurrentIfListen();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  QuizQuestion? get _current =>
      (_index >= 0 && _index < _questions.length) ? _questions[_index] : null;

  Future<void> _onSelect(int optionIndex) async {
    if (_answered) return;
    final q = _current;
    if (q == null) return;
    final ok = q.isCorrect(optionIndex);
    setState(() {
      _selected = optionIndex;
      _answered = true;
      if (ok) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
      _sessionWrongIds = QuizEngine.applySessionWrong(
        current: _sessionWrongIds,
        wordId: q.target.id,
        correct: ok,
      );
    });
    if (ok) {
      await widget.store.removeWrong(q.target.id);
      final celebrate = await widget.store.bumpTodayCount();
      if (celebrate && mounted) {
        showGoalCelebratedBanner(
          context,
          count: widget.store.todayCount(),
          goal: widget.store.dailyGoal(),
        );
      }
    } else {
      await widget.store.markWrong(q.target.id);
      if (_effectiveListen) {
        try {
          await _speak(q.target.word);
        } catch (_) {}
      }
    }
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
      _spellOk = null;
      _spellCtrl.clear();
    });
    if (_poolWrongOnly) {
      final wrong = widget.store.wrongIds();
      final left = _questions.skip(_index).where((q) => wrong.contains(q.target.id)).length;
      if (left == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('错词已测完')),
        );
        setState(() {
          _poolWrongOnly = false;
          _index = _questions.length;
        });
        return;
      }
    }
    _speakCurrentIfListen();
  }

  bool get _effectiveListen =>
      !_forceMeaning && _variant == 'listen' && _listenAvailable;

  bool get _isSpell => _variant == 'spell' && !_forceMeaning;

  /// 听写：听音后默写（判分前不露拼写/中文）.
  bool get _isDictation =>
      !_forceMeaning && _variant == 'dictation' && _listenAvailable;

  bool get _usesSpellInput => _isSpell || _isDictation;

  /// 看词选义：英文题干 + 中文义选项.
  bool get _isWordPick => !_forceMeaning && _variant == 'word';

  /// Options show Chinese meanings (listen or word-pick).
  bool get _usesMeaningOptions => _effectiveListen || _isWordPick;

  String get _segmentValue {
    if (_forceMeaning) return 'meaning';
    if (_isWordPick) return 'word';
    if (_effectiveListen) return 'listen';
    if (_isSpell) return 'spell';
    if (_isDictation) return 'dictation';
    return 'meaning';
  }

  Future<void> _checkSpell() async {
    if (_answered) return;
    final q = _current;
    if (q == null) return;
    final grade = QuizEngine.gradeSpell(input: _spellCtrl.text, target: q.target.word);
    if (grade == SpellGrade.empty) {
      if (!mounted) return;
      if (_isDictation) {
        _spellFocus.requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('先写出单词')),
        );
      }
      return;
    }
    final ok = grade == SpellGrade.correct;
    setState(() {
      _answered = true;
      _spellOk = ok;
      if (ok) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
      _sessionWrongIds = QuizEngine.applySessionWrong(
        current: _sessionWrongIds,
        wordId: q.target.id,
        correct: ok,
      );
    });
    if (ok) {
      await widget.store.removeWrong(q.target.id);
      final celebrate = await widget.store.bumpTodayCount();
      if (celebrate && mounted) {
        showGoalCelebratedBanner(
          context,
          count: widget.store.todayCount(),
          goal: widget.store.dailyGoal(),
        );
      }
    } else {
      await widget.store.markWrong(q.target.id);
    }
  }

  Future<void> _speak(String text) async {
    await _speaker.setAccent(widget.store.ttsAccent());
    await _speaker.speak(text);
  }

  Future<void> _speakCurrentIfListen() async {
    final q = _current;
    if (q == null) return;
    if (_effectiveListen) {
      try {
        await _speak(q.target.word);
      } catch (_) {
        await _degradeToMeaning();
      }
      return;
    }
    if (_isDictation) {
      try {
        await _speak(q.target.word);
      } catch (_) {
        await _degradeDictation();
      }
    }
  }

  Future<void> _degradeToMeaning() async {
    if (!mounted) return;
    _forceMeaning = true;
    _variant = 'meaning';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('暂时没法朗读，已改为看中文选英文')),
    );
    setState(() {});
    await _boot();
  }

  Future<void> _degradeDictation() async {
    if (!mounted) return;
    _forceMeaning = true;
    _variant = 'meaning';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('没法朗读，先检查系统语音包')),
    );
    setState(() {});
    await _boot();
  }


  Future<void> _setPoolWrongOnly(bool wrongOnly) async {
    if (wrongOnly == _poolWrongOnly) return;
    if (wrongOnly && _wrongInScope == 0) {
      if (!mounted) return;
      final unit = widget.store.selectedBookId() == null
          ? null
          : widget.store.unitFilterForBook(widget.store.selectedBookId()!);
      final msg = widget.mode == QuizMode.unit && (unit ?? '').isNotEmpty
          ? '本单元没有错词'
          : '还没有错词，先去学或自测';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    setState(() => _poolWrongOnly = wrongOnly);
    await _boot();
    if (!mounted) return;
    if (wrongOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('改测错词 · $_wrongInScope 个')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('改测全部')),
      );
    }
  }

  Future<void> _onVariantChanged(String next) async {
    if ((next == 'listen' || next == 'dictation') && !_listenAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没法朗读，先检查系统语音包')),
      );
      return;
    }
    await widget.store.setQuizVariant(next);
    setState(() {
      _variant = next;
      _forceMeaning = false;
    });
    await _boot();
  }

  Future<void> _replayListen() async {
    final q = _current;
    if (q == null) return;
    try {
      await _speak(q.target.word);
    } catch (_) {
      if (_isDictation) {
        await _degradeDictation();
      } else {
        await _degradeToMeaning();
      }
    }
  }


  List<Word> _distractorBookWords() {
    if (_book != null) return _book!.words;
    final byId = <String, Word>{};
    for (final q in _questions) {
      byId[q.target.id] = q.target;
      for (final o in q.options) {
        byId[o.id] = o;
      }
    }
    return byId.values.toList();
  }

  Future<void> _startWrongRetry() async {
    final wrongIds = List<String>.from(_sessionWrongIds);
    if (wrongIds.isEmpty) return;
    final bookWords = _distractorBookWords();
    final wrongWords = QuizEngine.wordsForRetry(
      bookWords: bookWords,
      wrongIdsInOrder: wrongIds,
    );
    if (wrongWords.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂时没法组卷，先回学习')),
      );
      return;
    }
    final session = QuizEngine.buildRetrySession(
      wrongWordsInOrder: wrongWords,
      bookWords: bookWords,
      listenMode: _usesMeaningOptions,
    );
    if (session.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂时没法组卷，先回学习')),
      );
      return;
    }
    setState(() {
      _retryRound = true;
      _questions = session;
      _index = 0;
      _selected = null;
      _answered = false;
      _spellOk = null;
      _spellCtrl.clear();
      _correctCount = 0;
      _wrongCount = 0;
      _sessionWrongIds = [];
      _loading = false;
      _error = null;
    });
    await _speakCurrentIfListen();
  }

  void _backToLearn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String get _title {
    if (_retryRound) return '错题再练';
    switch (widget.mode) {
      case QuizMode.wrong:
        return widget.wrongUnitScoped ? '自测错词·当前单元' : '自测错词';
      case QuizMode.unit:
        final id = widget.store.selectedBookId();
        final unit = id == null ? null : widget.store.unitFilterForBook(id);
        return unit == null || unit.isEmpty ? '自测当前单元' : '自测 · $unit';
      case QuizMode.book:
        return '自测本词书';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) return body;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(_title)),
      body: body,
    );
  }


  static const Color _quizTeal = Color(0xFF0D9488);

  ButtonStyle get _quizFilledStyle => FilledButton.styleFrom(
        backgroundColor: _quizTeal,
        foregroundColor: Colors.white,
      );

  Widget _quizPaper({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
  }) {
    final scheme = Theme.of(context).colorScheme;
    final paper = Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (!widget.embedded)
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
              TextButton(onPressed: _prepareAndBoot, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    if (_index >= _questions.length) {
      final total = _correctCount + _wrongCount;
      final rate = total == 0 ? 0 : ((_correctCount * 100) / total).round();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '本轮自测完成',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  '$rate%',
                  key: const ValueKey('quiz_end_rate'),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: _quizTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '正确 $_correctCount / $total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (rate < 60) ...[
                  const SizedBox(height: 8),
                  Text('先回认读过一遍再测，记得更牢。', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ] else if (rate >= 90) ...[
                  const SizedBox(height: 8),
                  Text('很棒，可以换下一单元了。', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
                if (_sessionWrongIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '本场错了 ${_sessionWrongIds.length} 个',
                    key: const ValueKey('quiz_end_wrong_hint'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                if (_sessionWrongIds.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const ValueKey('quiz_end_wrong_retry'),
                      onPressed: _startWrongRetry,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('错题再练', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('quiz_end_back'),
                    style: _quizFilledStyle,
                    onPressed: _backToLearn,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('回学习', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _current!;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _book?.title ?? widget.seedBookTitle ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Text(
            _retryRound
                ? '错题再练 · ${_questions.length}'
                : '自测 · 题 ${_index + 1}/${_questions.length}',
            key: ValueKey(_retryRound ? 'quiz_retry_badge' : 'quiz_progress_label'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 400;
              return AnimatedSize(
                duration: const Duration(milliseconds: 150),
                child: SegmentedButton<String>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'meaning',
                      label: Text(narrow ? '义' : '看义选词'),
                      tooltip: '看义选词',
                      icon: narrow ? null : const Icon(Icons.translate),
                    ),
                    ButtonSegment(
                      value: 'word',
                      label: Text(narrow ? '词' : '看词选义'),
                      tooltip: '看词选义',
                      icon: narrow ? null : const Icon(Icons.abc),
                    ),
                    ButtonSegment(
                      value: 'listen',
                      label: Text(narrow ? '听' : '听音选义'),
                      tooltip: '听音选义',
                      icon: narrow ? null : const Icon(Icons.hearing),
                      enabled: _listenAvailable,
                    ),
                    ButtonSegment(
                      value: 'spell',
                      label: Text(narrow ? '写' : '拼写'),
                      tooltip: '拼写默写',
                      icon: narrow ? null : const Icon(Icons.edit_outlined),
                    ),
                    ButtonSegment(
                      value: 'dictation',
                      label: Text(narrow ? '默' : '听写'),
                      tooltip: '听写',
                      icon: narrow ? null : const Icon(Icons.record_voice_over_outlined),
                      enabled: _listenAvailable,
                    ),
                  ],
                  selected: {_segmentValue},
                  onSelectionChanged: _retryRound
                      ? null
                      : (s) {
                          final v = s.first;
                          if ((v == 'listen' || v == 'dictation') && !_listenAvailable) {
                            return;
                          }
                          _onVariantChanged(v);
                        },
                ),
              );
            },
          ),
          if (!_listenAvailable) ...[
            const SizedBox(height: 6),
            Text(
              '请安装系统英文语音包后再用听音 / 听写',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (widget.seedQuestions == null && !_retryRound) ...[
            const SizedBox(height: 8),
            Wrap(
              key: const ValueKey('quiz_pool_chips'),
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  key: const ValueKey('quiz_pool_all'),
                  label: const Text('全部词'),
                  selected: !_poolWrongOnly,
                  onSelected: (_) => _setPoolWrongOnly(false),
                ),
                FilterChip(
                  key: const ValueKey('quiz_pool_wrong'),
                  label: Text(_wrongInScope > 0 ? '只测错词 · $_wrongInScope' : '只测错词'),
                  selected: _poolWrongOnly,
                  onSelected: (v) {
                    if (!v && _poolWrongOnly) return;
                    _setPoolWrongOnly(true);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (_usesSpellInput)
            Expanded(
              child: ListView(
                key: ValueKey(_isDictation ? 'quiz_dictation_pane' : 'quiz_spell_pane'),
                children: [
                  _quizPaper(
                    key: ValueKey(_isDictation ? 'prompt_dictation' : 'prompt_spell'),
                    child: _isDictation
                          ? Column(
                              children: [
                                Text('听写', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 12),
                                Icon(Icons.volume_up, size: 56, color: scheme.onSurface),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    key: const ValueKey('quiz_dictation_replay'),
                                    onPressed: _replayListen,
                                    icon: const Icon(Icons.replay),
                                    label: const Text('再听'),
                                  ),
                                ),
                                if (_answered) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    q.target.word,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  q.promptMeaning,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: ValueKey(
                      _isDictation ? 'quiz_dictation_input' : 'quiz_spell_input',
                    ),
                    controller: _spellCtrl,
                    focusNode: _spellFocus,
                    enabled: !_answered,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: _isDictation ? '写出你听到的单词' : '输入英文单词',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (_) => _checkSpell(),
                  ),
                  const SizedBox(height: 12),
                  if (_answered) ...[
                    if (_spellOk == true)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: _quizTeal, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _isDictation ? '拼对了' : '拼对了',
                            style: const TextStyle(
                              color: _quizTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '正确答案：${q.target.word}',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    key: ValueKey(
                      _answered
                          ? (_isDictation ? 'quiz_dictation_next' : 'quiz_spell_next')
                          : (_isDictation ? 'quiz_dictation_check' : 'quiz_spell_check'),
                    ),
                    style: _quizFilledStyle,
                    onPressed: _answered ? _next : _checkSpell,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _answered
                            ? (_index + 1 >= _questions.length ? '查看结果' : '下一题')
                            : (_isDictation ? '提交' : '检查'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 8),
                ],
              ),
            )
          else ...[
            _quizPaper(
              key: ValueKey(
                _effectiveListen
                    ? 'prompt_listen'
                    : (_isWordPick ? 'prompt_word' : 'prompt_meaning'),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: _isWordPick ? 16 : 28,
              ),
              child: _effectiveListen
                    ? Column(
                        children: [
                          Text('听英文，选意思', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 12),
                          Icon(Icons.volume_up, size: 56, color: scheme.onSurface),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              key: const ValueKey('quiz_replay'),
                              onPressed: _answered ? null : _replayListen,
                              icon: const Icon(Icons.replay),
                              label: const Text('再听一遍'),
                            ),
                          ),
                          if (_answered) ...[
                            const SizedBox(height: 12),
                            Text(
                              '${q.target.word} · ${q.target.meaning}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      )
                    : _isWordPick
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('选出正确的中文意思', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              Text(
                                q.target.word,
                                key: const ValueKey('prompt_word_text'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                              ),
                              IconButton(
                                key: const ValueKey('quiz_word_speak'),
                                tooltip: '朗读',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _speak(q.target.word),
                                icon: Icon(Icons.volume_up, color: scheme.onSurface),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text('选出对应的英文单词', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 12),
                              Text(
                                q.promptMeaning,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Widget optionTile(int i, {required bool compact}) {
                    final opt = q.options[i];
                    Color? bg;
                    Color? fg;
                    BorderSide? side;
                    if (_answered) {
                      if (i == q.correctIndex) {
                        bg = scheme.primaryContainer;
                        fg = scheme.onPrimaryContainer;
                        side = const BorderSide(color: _quizTeal, width: 2);
                      } else if (i == _selected) {
                        bg = scheme.errorContainer;
                        fg = scheme.onErrorContainer;
                        side = BorderSide(color: scheme.error, width: 2);
                      }
                    }
                    final label = _usesMeaningOptions ? opt.meaning : opt.word;
                    final row = SizedBox(
                      height: compact ? 48 : 56,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: bg,
                                foregroundColor: fg,
                                side: side,
                                alignment: Alignment.center,
                                padding: compact
                                    ? const EdgeInsets.symmetric(horizontal: 8)
                                    : null,
                              ),
                              onPressed: _answered ? null : () => _onSelect(i),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _usesMeaningOptions ? 16 : 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (!_usesMeaningOptions)
                            IconButton(
                              tooltip: '朗读',
                              onPressed: () => _speak(opt.word),
                              icon: Icon(Icons.volume_up, color: scheme.onSurface),
                            ),
                        ],
                      ),
                    );
                    return row;
                  }

                  // Wide/short: 2-col grid so all 4 meanings fit without scrolling off.
                  final rowH = 56.0;
                  final need = q.options.length * rowH + (q.options.length - 1) * 10;
                  final useGrid = _isWordPick &&
                      constraints.maxWidth >= 300 &&
                      constraints.maxHeight < need;

                  if (useGrid) {
                    return GridView.builder(
                      key: const ValueKey('quiz_options_grid'),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 52,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: q.options.length,
                      itemBuilder: (context, i) => optionTile(i, compact: true),
                    );
                  }

                  return ListView.separated(
                    key: const ValueKey('quiz_options_list'),
                    itemCount: q.options.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => optionTile(i, compact: false),
                  );
                },
              ),
            ),
            if (_answered) ...[
              const SizedBox(height: 8),
              if (_selected != q.correctIndex)
                Text(
                  _usesMeaningOptions
                      ? '正确答案：${q.target.word} · ${q.target.meaning}'
                      : '正确答案：${q.target.word}',
                  style: Theme.of(context).textTheme.titleSmall,
                )
              else
                const Text('答对了！', style: TextStyle(color: _quizTeal, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
            const SizedBox(height: 8),
            FilledButton(
              style: _quizFilledStyle,
              onPressed: _answered ? _next : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_index + 1 >= _questions.length ? '查看结果' : '下一题', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}
