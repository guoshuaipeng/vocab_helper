import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/review_queue.dart';
import '../services/wordbook_repository.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.bookId,
    required this.onNeedSetup,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String? bookId;
  final VoidCallback onNeedSetup;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ReviewQueue? _queue;
  WordBook? _book;
  bool _flipped = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
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
      final learned = widget.store.learnedIds();
      final pending = book.words.where((w) => !learned.contains(w.id)).toList();
      final list = pending.isEmpty ? List<Word>.from(book.words) : pending;
      await widget.store.touchActive();
      setState(() {
        _book = book;
        _queue = ReviewQueue(list);
        _flipped = false;
        _loading = false;
      });
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
  }

  void _onUnknown() {
    final q = _queue;
    if (q == null) return;
    setState(() {
      q.markUnknown();
      _flipped = false;
    });
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
            const Text('本轮单词都过完啦！', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('本轮认识 ${q.knownCount} 个', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: _boot, child: const Text('再来一轮')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_book?.title ?? ''} · 剩余 ${q.remaining} · 本轮认识 ${q.knownCount}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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