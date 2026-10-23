import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/wordbook_repository.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.selectedBookId,
    required this.onChangeBook,
    required this.onBookSelected,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String? selectedBookId;
  final VoidCallback onChangeBook;
  final VoidCallback onBookSelected;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<WordBookMeta> _catalog = [];
  bool _loading = true;
  final _query = TextEditingController();
  List<_Hit> _hits = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    widget.repo.loadCatalog().then((c) {
      setState(() {
        _catalog = c;
        _loading = false;
      });
    });
    _query.addListener(_onQuery);
  }

  @override
  void dispose() {
    _query.removeListener(_onQuery);
    _query.dispose();
    super.dispose();
  }

  Future<void> _onQuery() async {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _hits = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final hits = <_Hit>[];
    for (final meta in _catalog) {
      try {
        final book = await widget.repo.loadBook(meta.id);
        for (final w in book.words) {
          if (w.word.toLowerCase().contains(q) || w.meaning.contains(q)) {
            hits.add(_Hit(book: book, word: w));
            if (hits.length >= 40) break;
          }
        }
      } catch (_) {}
      if (hits.length >= 40) break;
    }
    if (!mounted) return;
    if (_query.text.trim().toLowerCase() != q) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  Future<void> _selectBook(WordBookMeta b) async {
    if (b.id == widget.selectedBookId) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('切换到这本词书？'),
        content: Text('${b.title}\n共 ${b.wordCount} 词。学习进度按词书分开保存。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('切换')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.store.setSelectedBookId(b.id);
    widget.onBookSelected();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到 ${b.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final versions = widget.repo.versionsOf(_catalog);
    final searching = _query.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: widget.onChangeBook,
          icon: const Icon(Icons.tune),
          label: const Text('更换教材 / 年级'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _query,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: '搜索英文或中文释义',
            border: const OutlineInputBorder(),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _query.clear(),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (searching) ...[
          if (_searching) const LinearProgressIndicator(),
          Text(
            _hits.isEmpty && !_searching ? '没有匹配的单词' : '找到 ${_hits.length} 条（最多显示 40）',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ..._hits.map((h) => Card(
                child: ListTile(
                  title: Text(h.word.word),
                  subtitle: Text('${h.word.meaning} · ${h.book.title}'),
                  trailing: h.book.id == widget.selectedBookId
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.menu_book_outlined),
                  onTap: () {
                    final meta = _catalog.firstWhere((m) => m.id == h.book.id);
                    _selectBook(meta);
                  },
                ),
              )),
        ] else ...[
          Text('也可直接点下面的词书切换', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ...versions.map((v) {
            final books = widget.repo.booksOf(_catalog, v);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...books.map((b) {
                  final selected = b.id == widget.selectedBookId;
                  return Card(
                    color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: ListTile(
                      title: Text(b.title),
                      subtitle: Text('${b.grade} · 共 ${b.wordCount} 词'),
                      trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
                      onTap: () => _selectBook(b),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
          Text(
            '小学（人教/外研/沪教）词表为公开资料精选；初中人教版为开源完整词库。后续可继续补全各版本全书。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _Hit {
  _Hit({required this.book, required this.word});
  final WordBook book;
  final Word word;
}