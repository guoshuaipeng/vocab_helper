import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_store.dart';
import '../services/wordbook_repository.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.onRefresh,
    required this.onChangeBook,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final VoidCallback onRefresh;
  final VoidCallback onChangeBook;

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  WordBookMeta? _book;
  bool _loadingBook = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void didUpdateWidget(covariant MeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.selectedBookId() != widget.store.selectedBookId()) {
      _loadBook();
    }
  }

  Future<void> _loadBook() async {
    setState(() => _loadingBook = true);
    final id = widget.store.selectedBookId();
    if (id == null || id.isEmpty) {
      setState(() {
        _book = null;
        _loadingBook = false;
      });
      return;
    }
    try {
      final catalog = await widget.repo.loadCatalog();
      WordBookMeta? found;
      for (final b in catalog) {
        if (b.id == id) {
          found = b;
          break;
        }
      }
      setState(() {
        _book = found;
        _loadingBook = false;
      });
    } catch (_) {
      setState(() {
        _book = null;
        _loadingBook = false;
      });
    }
  }

  Future<void> _confirmClear() async {
    final book = _book;
    if (book == null) return;
    final count = widget.store.learnedCountForBook(book.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空本词书进度？'),
        content: Text('将清除「${book.title}」里已标记认识的 $count 个单词，其他词书进度不受影响。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await widget.store.clearLearnedForBook(book.id);
    widget.onRefresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(removed == 0 ? '本词书暂无进度' : '已清除 $removed 个单词进度')),
    );
    setState(() {});
  }

  Future<void> _editGoal() async {
    final controller = TextEditingController(text: '${widget.store.dailyGoal()}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置每日目标'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每天新学单词数',
            helperText: '建议 5～100，默认 20',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final n = int.tryParse(controller.text.trim()) ?? widget.store.dailyGoal();
    await widget.store.setDailyGoal(n);
    widget.onRefresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.store.selectedBookId();
    final bookLearned = bookId == null ? 0 : widget.store.learnedCountForBook(bookId);
    final goal = widget.store.dailyGoal();
    final today = widget.store.todayCount();
    final progress = goal == 0 ? 0.0 : (today / goal).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        await _loadBook();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('我的进度', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingBook
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前词书', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _book == null ? '尚未选择' : _book!.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        if (_book != null) ...[
                          const SizedBox(height: 4),
                          Text('${_book!.version} · ${_book!.grade} · 本词书已学 $bookLearned / ${_book!.wordCount}'),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: widget.onChangeBook,
                              icon: const Icon(Icons.tune),
                              label: const Text('更换教材'),
                            ),
                            if (_book != null)
                              OutlinedButton.icon(
                                onPressed: _confirmClear,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('清空本词书进度'),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('今日目标', style: Theme.of(context).textTheme.titleMedium)),
                      TextButton(onPressed: _editGoal, child: const Text('修改')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$today / $goal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(
                    widget.store.todayGoalMet ? '今日目标已完成，棒！' : '再学 ${goal - today} 个就达标',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StatCard(label: '已学单词（全部）', value: '${widget.store.learnedCount()}'),
          const SizedBox(height: 12),
          _StatCard(label: '今日新学', value: '$today'),
          const SizedBox(height: 12),
          _StatCard(label: '连续天数', value: '${widget.store.streakDays()}'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}