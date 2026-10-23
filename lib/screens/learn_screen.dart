import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/review_queue.dart';
import '../services/word_speaker.dart';
import '../services/wordbook_repository.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.bookId,
    required this.onNeedSetup,
    this.reviewWrongOnly = false,
    this.speaker,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String? bookId;
  final VoidCallback onNeedSetup;
  final bool reviewWrongOnly;
  final WordSpeaker? speaker;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ReviewQueue? _queue;
  WordBook? _book;
  bool _flipped = false;
  bool _loading = true;
  String? _error;
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

  @override
  void didUpdateWidget(covariant LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId || oldWidget.reviewWrongOnly != widget.reviewWrongOnly) {
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
      var scoped = book.words;
      if (unitFilter != null && unitFilter.isNotEmpty) {
        scoped = book.words.where((w) => w.unit == unitFilter).toList();
      }

      List<Word> list;
      if (widget.reviewWrongOnly) {
        final wrong = widget.store.wrongIds();
        list = scoped.where((w) => wrong.contains(w.id)).toList();
        if (list.isEmpty) {
          setState(() {
            _book = book;
            _queue = ReviewQueue(list);
            _flipped = false;
            _loading = false;
            _error = unitFilter == null
                ? '错词本是空的，先在学习里点「不认识」吧'
                : '当前单元没有错词，可换单元或学完全书后再复习';
          });
          return;
        }
      } else {
        if (scoped.isEmpty) {
          setState(() {
            _book = book;
            _queue = ReviewQueue(const []);
            _flipped = false;
            _loading = false;
            _error = '这个单元暂时没有单词';
          });
          return;
        }
        final learned = widget.store.learnedIds();
        final pending = scoped.where((w) => !learned.contains(w.id)).toList();
        list = pending.isEmpty ? List<Word>.from(scoped) : pending;
      }
      await widget.store.touchActive();
      setState(() {
        _book = book;
        _queue = ReviewQueue(list);
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

  Future<void> _onKnown() async {
    final q = _queue;
    final cur = q?.current;
    if (q == null || cur == null) return;
    await widget.store.markLearned(cur.id);
    setState(() {
      q.markKnown();
      _flipped = false;
    });
    await _maybeAutoSpeak();
  }

  Future<void> _onUnknown() async {
    final q = _queue;
    final cur = q?.current;
    if (q == null || cur == null) return;
    await widget.store.markWrong(cur.id);
    setState(() {
      q.markUnknown();
      _flipped = false;
    });
    await _maybeAutoSpeak();
  }

  Future<void> _pickUnit(String? unit) async {
    final id = widget.bookId;
    if (id == null) return;
    await widget.store.setUnitFilterForBook(id, unit);
    await _boot();
  }

  Future<void> _maybeAutoSpeak() async {
    if (!widget.store.autoSpeak()) return;
    await _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    final word = _queue?.current;
    if (word == null) return;
    await _speaker.setAccent(widget.store.ttsAccent());
    await _speaker.speak(word.word);
  }

  @override
  Widget build(BuildContext context) {
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
              FilledButton(onPressed: widget.onNeedSetup, child: const Text('去选择年级')),
              TextButton(onPressed: _boot, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final q = _queue!;
    final word = q.current;
    if (word == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.reviewWrongOnly ? '错词本本轮复习完啦！' : '本轮单词都过完啦！',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text('本轮认识 ${q.knownCount} 个', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: _boot, child: const Text('再来一轮')),
          ],
        ),
      );
    }

    final bookId = widget.bookId;
    final selectedUnit = bookId == null ? null : widget.store.unitFilterForBook(bookId);
    final units = _book?.unitNames() ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.reviewWrongOnly ? '错词复习 · ${_book?.title ?? ''}' : (_book?.title ?? ''),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '剩余 ${q.remaining} · 本轮认识 ${q.knownCount} · 今日 ${widget.store.todayCount()}/${widget.store.dailyGoal()}${widget.store.todayGoalMet ? ' · 已达标' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!widget.reviewWrongOnly && units.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('全部'),
                      selected: selectedUnit == null,
                      onSelected: (_) => _pickUnit(null),
                    ),
                  ),
                  ...units.map((u) {
                    final selected = selectedUnit == u;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(u),
                        selected: selected,
                        onSelected: (_) => _pickUnit(selected ? null : u),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: '朗读',
                      onPressed: _speakCurrent,
                      icon: const Icon(Icons.volume_up),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _flipped = !_flipped),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _flipped
                                ? Column(
                                    key: const ValueKey('back'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(word.meaning, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                      if ((word.example ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(word.example!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
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
                                      if ((word.phonetic ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(word.phonetic!, style: Theme.of(context).textTheme.titleMedium),
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
                child: OutlinedButton(
                  onPressed: _onUnknown,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('不认识', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _onKnown,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('认识', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}