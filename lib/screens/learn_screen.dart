import 'package:flutter/material.dart';

import '../data/seed_words.dart';
import '../services/progress_store.dart';
import '../services/review_queue.dart';
import '../models/word.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late ReviewQueue _queue;
  bool _flipped = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  void _boot() {
    try {
      if (seedWords.isEmpty) {
        setState(() => _error = '词库为空，请稍后再试。');
        return;
      }
      final learned = widget.store.learnedIds();
      final pending = seedWords.where((w) => !learned.contains(w.id)).toList();
      final list = pending.isEmpty ? List<Word>.from(seedWords) : pending;
      _queue = ReviewQueue(list);
      _flipped = false;
      _error = null;
      widget.store.touchActive();
      setState(() {});
    } catch (e) {
      setState(() => _error = '加载失败：$e');
    }
  }

  Future<void> _onKnown() async {
    final cur = _queue.current;
    if (cur == null) return;
    await widget.store.markLearned(cur.id);
    setState(() {
      _queue.markKnown();
      _flipped = false;
    });
  }

  void _onUnknown() {
    setState(() {
      _queue.markUnknown();
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _boot, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final word = _queue.current;
    if (word == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('本轮单词都过完啦！', style: TextStyle(fontSize: 20)),
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
              '剩余 ${_queue.remaining} 词 · 本轮认识 ${_queue.knownCount}',
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
                                if (word.example != null) ...[
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
                                if (word.phonetic != null) ...[
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
