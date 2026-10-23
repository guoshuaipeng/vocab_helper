import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/quiz_engine.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../services/wordbook_repository.dart';

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
  /// Effective variant: meaning | word | listen | spell.
  String _variant = 'meaning';
  bool _listenAvailable = true;
  /// After TTS failure, force meaning for the rest of the round.
  bool _forceMeaning = false;
  final TextEditingController _spellCtrl = TextEditingController();
  final FocusNode _spellFocus = FocusNode();
  /// null until checked; true/false after grade.
  bool? _spellOk;

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
    _prepareAndBoot();
  }

  Future<void> _prepareAndBoot() async {
    _listenAvailable = await _speaker.englishVoiceAvailable();
    if (!_listenAvailable && _variant == 'listen') {
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
      List<Word> pool;
      if (widget.mode == QuizMode.wrong) {
        pool = filterWrongWords(
          words: book.words,
          wrongIds: widget.store.wrongIds(),
          unitFilter: widget.wrongUnitScoped ? unitFilter : null,
        );
        if (pool.isEmpty) {
          setState(() {
            _book = book;
            _loading = false;
            _error = widget.wrongUnitScoped && (unitFilter ?? '').isNotEmpty
                ? '当前单元没有错词可自测'
                : '错词本是空的，先去学习或自测里答错几题吧';
          });
          return;
        }
      } else if (widget.mode == QuizMode.unit) {
        if (unitFilter == null || unitFilter.isEmpty) {
          setState(() {
            _book = book;
            _loading = false;
            _error = '请先在学习页选择一个单元，再自测当前单元';
          });
          return;
        }
        pool = QuizEngine.poolForUnit(bookWords: book.words, unitFilter: unitFilter);
        if (pool.isEmpty) {
          setState(() {
            _book = book;
            _loading = false;
            _error = '这个单元暂时没有单词';
          });
          return;
        }
      } else {
        pool = List<Word>.from(book.words);
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
    });
    if (ok) {
      await widget.store.removeWrong(q.target.id);
      await widget.store.bumpTodayCount();
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
    _speakCurrentIfListen();
  }

  bool get _effectiveListen =>
      !_forceMeaning && _variant == 'listen' && _listenAvailable;

  bool get _isSpell => _variant == 'spell' && !_forceMeaning;

  /// 看词选义：英文题干 + 中文义选项.
  bool get _isWordPick => !_forceMeaning && _variant == 'word';

  /// Options show Chinese meanings (listen or word-pick).
  bool get _usesMeaningOptions => _effectiveListen || _isWordPick;

  String get _segmentValue {
    if (_forceMeaning) return 'meaning';
    if (_isWordPick) return 'word';
    if (_effectiveListen) return 'listen';
    if (_isSpell) return 'spell';
    return 'meaning';
  }

  Future<void> _checkSpell() async {
    if (_answered) return;
    final q = _current;
    if (q == null) return;
    final grade = QuizEngine.gradeSpell(input: _spellCtrl.text, target: q.target.word);
    if (grade == SpellGrade.empty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先写出单词')),
      );
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
    });
    if (ok) {
      await widget.store.removeWrong(q.target.id);
      await widget.store.bumpTodayCount();
    } else {
      await widget.store.markWrong(q.target.id);
    }
  }

  Future<void> _speak(String text) async {
    await _speaker.setAccent(widget.store.ttsAccent());
    await _speaker.speak(text);
  }

  Future<void> _speakCurrentIfListen() async {
    if (!_effectiveListen) return;
    final q = _current;
    if (q == null) return;
    try {
      await _speak(q.target.word);
    } catch (_) {
      await _degradeToMeaning();
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

  Future<void> _onVariantChanged(String next) async {
    if (next == 'listen' && !_listenAvailable) return;
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
      await _degradeToMeaning();
    }
  }

  String get _title {
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
      final scheme = Theme.of(context).colorScheme;
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
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
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
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('quiz_end_retry'),
                  onPressed: _prepareAndBoot,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('再测一轮', style: TextStyle(fontSize: 18)),
                  ),
                ),
                if (!widget.embedded)
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '自测 · 题 ${_index + 1}/${_questions.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 6,
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
                  ],
                  selected: {_segmentValue},
                  onSelectionChanged: (s) {
                    final v = s.first;
                    if (v == 'listen' && !_listenAvailable) return;
                    _onVariantChanged(v);
                  },
                ),
              );
            },
          ),
          if (!_listenAvailable) ...[
            const SizedBox(height: 6),
            Text(
              '请安装系统英文语音包后再用听音',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          if (_isSpell)
            Expanded(
              child: ListView(
                key: const ValueKey('quiz_spell_pane'),
                children: [
                  Card(
                    key: const ValueKey('prompt_spell'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      child: Column(
                        children: [
                          Text(
                            q.promptMeaning,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('quiz_spell_input'),
                    controller: _spellCtrl,
                    focusNode: _spellFocus,
                    enabled: !_answered,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '输入英文单词',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onSubmitted: (_) => _checkSpell(),
                  ),
                  const SizedBox(height: 12),
                  if (_answered) ...[
                    if (_spellOk == true)
                      Text('拼对了', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 16))
                    else
                      Text(
                        '正确答案：${q.target.word}',
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    key: ValueKey(_answered ? 'quiz_spell_next' : 'quiz_spell_check'),
                    onPressed: _answered ? _next : _checkSpell,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _answered
                            ? (_index + 1 >= _questions.length ? '查看结果' : '下一题')
                            : '检查',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 8),
                ],
              ),
            )
          else ...[
            Card(
              key: ValueKey(
                _effectiveListen
                    ? 'prompt_listen'
                    : (_isWordPick ? 'prompt_word' : 'prompt_meaning'),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: _isWordPick ? 16 : 28,
                ),
                child: _effectiveListen
                    ? Column(
                        children: [
                          Text('听英文，选意思', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 12),
                          Icon(Icons.volume_up, size: 56, color: scheme.primary),
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
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                key: const ValueKey('quiz_word_speak'),
                                tooltip: '朗读',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _speak(q.target.word),
                                icon: const Icon(Icons.volume_up),
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
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
                        side = BorderSide(color: scheme.primary, width: 2);
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
                              icon: const Icon(Icons.volume_up),
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
                Text('答对了！', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
            const SizedBox(height: 8),
            FilledButton(
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
