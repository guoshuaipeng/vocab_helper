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

  @override
  void initState() {
    super.initState();
    widget.repo.loadCatalog().then((c) {
      setState(() {
        _catalog = c;
        _loading = false;
      });
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: widget.onChangeBook,
          icon: const Icon(Icons.tune),
          label: const Text('更换教材 / 年级'),
        ),
        const SizedBox(height: 8),
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
    );
  }
}