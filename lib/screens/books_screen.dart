import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/cross_book_search.dart';
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
  List<CrossBookSearchHit> _hits = [];
  bool _searching = false;
  bool _indexReady = false;
  int _querySeq = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _query.addListener(_onQuery);
  }

  Future<void> _bootstrap() async {
    final c = await widget.repo.loadCatalog();
    if (!mounted) return;
    setState(() {
      _catalog = c;
      _loading = false;
    });
    // Background prebuild — do not block list UI.
    // ignore: unawaited_futures
    widget.repo.ensureSearchIndex().then((_) {
      if (!mounted) return;
      setState(() => _indexReady = widget.repo.searchIndex.isReady);
      if (_query.text.trim().isNotEmpty) {
        _runQuery(_query.text);
      }
    });
  }

  @override
  void dispose() {
    _query.removeListener(_onQuery);
    _query.dispose();
    super.dispose();
  }

  void _onQuery() {
    _runQuery(_query.text);
  }

  Future<void> _runQuery(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = [];
        _searching = false;
      });
      return;
    }

    final seq = ++_querySeq;

    if (!widget.repo.searchIndex.isReady) {
      setState(() => _searching = true);
      await widget.repo.ensureSearchIndex();
      if (!mounted || seq != _querySeq) return;
      setState(() => _indexReady = widget.repo.searchIndex.isReady);
    }

    if (!mounted || seq != _querySeq) return;
    final hits = widget.repo.search(
      q,
      currentBookId: widget.selectedBookId,
      limit: 40,
    );
    if (!mounted || seq != _querySeq) return;
    setState(() {
      _hits = hits;
      _searching = false;
      _indexReady = true;
    });
  }

  Future<void> _selectBook(WordBookMeta b) async {
    if (b.id == widget.selectedBookId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是这本')),
      );
      return;
    }
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

  List<Widget> _buildBookSections(ColorScheme scheme) {
    final recommended =
        _catalog.where((b) => b.id == WordbookRepository.recommendedBookId).toList();
    final versions = widget.repo.versionsOf(_catalog);
    final out = <Widget>[];
    if (recommended.isNotEmpty) {
      out.add(
        Text(
          '推荐跟课',
          key: const ValueKey('books_recommend_section'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
      out.add(const SizedBox(height: 8));
      out.add(_bookCard(recommended.first, scheme, forceRecommended: true));
      out.add(const SizedBox(height: 16));
    }
    for (final v in versions) {
      final books = widget.repo
          .booksOf(_catalog, v)
          .where((b) => b.id != WordbookRepository.recommendedBookId)
          .toList();
      if (books.isEmpty) continue;
      out.add(Text(v, style: Theme.of(context).textTheme.titleLarge));
      out.add(const SizedBox(height: 8));
      for (final b in books) {
        out.add(_bookCard(b, scheme));
      }
      out.add(const SizedBox(height: 16));
    }
    return out;
  }

  Widget _bookCard(WordBookMeta b, ColorScheme scheme, {bool forceRecommended = false}) {
    final selected = b.id == widget.selectedBookId;
    final recommended = forceRecommended || b.id == WordbookRepository.recommendedBookId;
    final base = b.sourceLabel.isEmpty
        ? '${b.grade} · 共 ${b.wordCount} 词'
        : '${b.grade} · 共 ${b.wordCount} 词 · ${b.sourceLabel}';
    return Card(
      key: recommended ? const ValueKey('books_recommended') : null,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: selected ? scheme.primaryContainer : null,
      child: ListTile(
        title: Text(b.title),
        subtitle: Text(recommended ? '$base · 推荐' : base),
        trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
        onTap: () => _selectBook(b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final searching = _query.text.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

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
          if (_searching || !_indexReady) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text(
              '正在准备搜索…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Text(
              _hits.isEmpty ? '没有匹配的单词' : '找到 ${_hits.length} 条（最多显示 40）',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          ..._hits.map((h) {
            final selected = h.meta.id == widget.selectedBookId;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
              child: ListTile(
                title: Text(h.word.word),
                subtitle: Text('${h.word.meaning} · ${h.meta.title}'),
                trailing: selected
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : const Icon(Icons.menu_book_outlined),
                onTap: () => _selectBook(h.meta),
              ),
            );
          }),
        ] else ...[
          Text('也可直接点下面的词书切换', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ..._buildBookSections(scheme),
          Text(
            '小学（人教/外研/沪教）词表为公开资料精选；初中人教版为开源完整词库。后续可继续补全各版本全书。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}