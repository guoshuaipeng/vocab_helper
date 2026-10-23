import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/quiz_engine.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../services/wordbook_repository.dart';

enum QuizMode {
  /// Current unit (or whole book if no unit filter).
  unit,
  /// Wrong-book words only (optionally scoped to current unit).
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
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final QuizMode mode;
  final bool wrongUnitScoped;
  final WordSpeaker? speaker;
  /// When set (tests), skip asset load and use these questions.
  final List<QuizQuestion>? seedQuestions;
  final String? seedBookTitle;

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
        _correctCount = 0;
        _wrongCount = 0;
        _loading = false;
        _error = widget.seedQuestions!.isEmpty ? '无法生成题目' : null;
      });
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
      } else {
        pool = QuizEngine.poolForUnit(bookWords: book.words, unitFilter: unitFilter);
        if (pool.isEmpty) {
          setState(() {
            _book = book;
            _loading = false;
            _error = '这个单元暂时没有单词';
          });
          return;
        }
      }

      final session = QuizEngine.buildSession(pool: pool, bookWords: book.words);
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
        _correctCount = 0;
        _wrongCount = 0;
        _loading = false;
      });
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
    } else {
      await widget.store.markWrong(q.target.id);
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
    });
  }

  Future<void> _speakCorrect() async {
    final q = _current;
    if (q == null) return;
    await _speaker.setAccent(widget.store.ttsAccent());
    await _speaker.speak(q.target.word);
  }

  String get _title {
    if (widget.mode == QuizMode.wrong) {
      return widget.wrongUnitScoped ? '自测错词·当前单元' : '自测错词';
    }
    final id = widget.store.selectedBookId();
    final unit = id == null ? null : widget.store.unitFilterForBook(id);
    if (unit != null && unit.isNotEmpty) return '自测 · $unit';
    return '自测本词书';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _buildBody(context),
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
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
              TextButton(onPressed: _boot, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    if (_index >= _questions.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('本轮自测结束', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('答对 $_correctCount · 答错 $_wrongCount', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('答错已进错词本；答对且曾在错词本已移出。', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _boot, child: const Text('再测一轮')),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
            ],
          ),
        ),
      );
    }

    final q = _current!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_book?.title ?? widget.seedBookTitle ?? ''} · ${_index + 1}/${_questions.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Text('看中文，选英文', style: Theme.of(context).textTheme.labelLarge),
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
            child: ListView.separated(
              itemCount: q.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
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
                return SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: bg,
                      foregroundColor: fg,
                      side: side,
                      alignment: Alignment.center,
                    ),
                    onPressed: _answered ? null : () => _onSelect(i),
                    child: Text(opt.word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          if (_answered) ...[
            const SizedBox(height: 8),
            if (_selected != q.correctIndex)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '正解：${q.target.word}',
                      style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: '朗读正解',
                    onPressed: _speakCorrect,
                    icon: const Icon(Icons.volume_up),
                  ),
                ],
              )
            else
              Text('答对了！', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _next,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_index + 1 >= _questions.length ? '查看结果' : '下一题', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


