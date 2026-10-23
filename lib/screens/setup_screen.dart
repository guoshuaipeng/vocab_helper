import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/wordbook_repository.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.onDone,
    this.allowSkip = false,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final VoidCallback onDone;
  final bool allowSkip;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  List<WordBookMeta> _catalog = [];
  String? _version;
  String? _bookId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await widget.repo.loadCatalog();
      setState(() {
        _catalog = catalog;
        _version = catalog.isNotEmpty ? catalog.first.version : null;
        final current = widget.store.selectedBookId();
        if (current != null && catalog.any((b) => b.id == current)) {
          _bookId = current;
          _version = catalog.firstWhere((b) => b.id == current).version;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '词书加载失败：$e';
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_bookId == null) return;
    await widget.store.setSelectedBookId(_bookId!);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final versions = widget.repo.versionsOf(_catalog);
    final books = _version == null ? <WordBookMeta>[] : widget.repo.booksOf(_catalog, _version!);

    return Scaffold(
      appBar: AppBar(title: const Text('选择教材与年级')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('教材版本', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: versions.map((v) {
              final selected = v == _version;
              return ChoiceChip(
                label: Text(v),
                selected: selected,
                onSelected: (_) => setState(() {
                  _version = v;
                  _bookId = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('年级 / 册别', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...books.map((b) {
            final selected = b.id == _bookId;
            return Card(
              color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
              child: ListTile(
                title: Text(b.grade),
                subtitle: Text('${b.title} · 共 ${b.wordCount} 词'),
                trailing: selected ? const Icon(Icons.check_circle) : null,
                onTap: () => setState(() => _bookId = b.id),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _bookId == null ? null : _confirm,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('开始学习', style: TextStyle(fontSize: 18)),
            ),
          ),
          if (widget.allowSkip) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: widget.onDone, child: const Text('取消')),
          ],
          const SizedBox(height: 16),
          Text(
            '人教版初中为开源完整词库；小学人教版/外研版为公开词表精选，后续可继续扩充。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}