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
    required this.onReviewWrong,
    required this.onReviewWrongCurrentUnit,
    required this.onQuizBook,
    required this.onQuizUnit,
    required this.onQuizWrong,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final VoidCallback onRefresh;
  final VoidCallback onChangeBook;
  final VoidCallback onReviewWrong;
  final VoidCallback onReviewWrongCurrentUnit;
  final VoidCallback onQuizBook;
  final VoidCallback onQuizUnit;
  final VoidCallback onQuizWrong;

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
    _rollDay();
  }

  Future<void> _rollDay() async {
    await widget.store.ensureDayRolled();
    if (mounted) setState(() {});
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


  Future<void> _confirmClearWrong(String bookId) async {
    final book = _book;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空错词？'),
        content: Text(
          book == null
              ? '将清空当前词书错词本，此操作不可撤销。'
              : '将清空「${book.title}」的错词本，此操作不可撤销。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final n = await widget.store.clearWrongForBook(bookId);
    if (!mounted) return;
    widget.onRefresh();
    setState(() {});
    messenger.showSnackBar(
      SnackBar(content: Text(n == 0 ? '错词本已空' : '已清空 $n 个错词')),
    );
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
                  const SizedBox(height: 8),
                  Text(
                    () {
                      final id = widget.store.selectedBookId();
                      if (id == null || id.isEmpty) return '暂无到期复习';
                      final due = widget.store.dueReviewCountForBook(id);
                      return due == 0 ? '暂无到期复习' : '待复习 $due 个（含到期词）';
                    }(),
                    key: const ValueKey('me_due_review'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _WeekCheckIn(store: widget.store),
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
                  Text('朗读口音', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en-US', label: Text('美音'), icon: Icon(Icons.volume_up)),
                      ButtonSegment(value: 'en-GB', label: Text('英音'), icon: Icon(Icons.volume_up)),
                    ],
                    selected: {widget.store.ttsAccent()},
                    onSelectionChanged: (s) async {
                      await widget.store.setTtsAccent(s.first);
                      widget.onRefresh();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('学习页点喇叭时使用该口音（依赖系统已安装的语音包）。', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('出现新词时自动朗读'),
                    value: widget.store.autoSpeak(),
                    onChanged: (v) async {
                      await widget.store.setAutoSpeak(v);
                      widget.onRefresh();
                      setState(() {});
                    },
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
                  Text('学习自测', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('看中文选英文，四选一。答错进错词本。', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final unit = bookId == null ? null : widget.store.unitFilterForBook(bookId);
                      final hasUnit = unit != null && unit.isNotEmpty;
                      final hasWrong = bookId != null && widget.store.wrongCountForBook(bookId) > 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: bookId == null ? null : widget.onQuizBook,
                                icon: const Icon(Icons.quiz_outlined),
                                label: const Text('自测本词书'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: (bookId != null && hasUnit) ? widget.onQuizUnit : null,
                                icon: const Icon(Icons.filter_list),
                                label: Text(hasUnit ? '自测$unit' : '自测当前单元'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: hasWrong ? widget.onQuizWrong : null,
                                icon: const Icon(Icons.fact_check_outlined),
                                label: const Text('自测错词'),
                              ),
                            ],
                          ),
                          if (!hasUnit && bookId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '提示：在学习页选一个单元后，可「自测当前单元」。',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      );
                    },
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
                  Text('错词本', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    bookId == null
                        ? '0'
                        : '${widget.store.wrongCountForBook(bookId)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('点「不认识」会加入本词书错词本；点「认识」会移出。', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final unit = bookId == null ? null : widget.store.unitFilterForBook(bookId);
                      final hasUnit = unit != null && unit.isNotEmpty;
                      final hasWrong = bookId != null && widget.store.wrongCountForBook(bookId) > 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasUnit)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('学习页当前单元：$unit', style: Theme.of(context).textTheme.bodySmall),
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: hasWrong ? widget.onReviewWrong : null,
                                icon: const Icon(Icons.replay),
                                label: const Text('复习全部错词'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: (hasWrong && hasUnit) ? widget.onReviewWrongCurrentUnit : null,
                                icon: const Icon(Icons.filter_list),
                                label: Text(hasUnit ? '只复习$unit' : '只复习当前单元'),
                              ),
                              if (bookId != null)
                                OutlinedButton(
                                  onPressed: !hasWrong ? null : () => _confirmClearWrong(bookId),
                                  child: const Text('清空错词'),
                                ),
                            ],
                          ),
                          if (!hasUnit && hasWrong)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '提示：在学习页选一个单元后，可「只复习当前单元」。',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      );
                    },
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


class _WeekCheckIn extends StatelessWidget {
  const _WeekCheckIn({required this.store});

  final ProgressStore store;

  static const _labels = ['一', '二', '三', '四', '五', '六', '日'];

  String _tooltip(CheckInDay day) {
    final goal = store.dailyGoal();
    switch (day.status) {
      case CheckInDayStatus.met:
        return '已达标';
      case CheckInDayStatus.missed:
        return '未达标（${day.count ?? 0}/$goal）';
      case CheckInDayStatus.empty:
        return '无记录';
      case CheckInDayStatus.todayProgress:
        return '今日 ${day.count ?? store.todayCount()}/$goal';
      case CheckInDayStatus.future:
        return '未到';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = store.weekCheckIns();
    final streak = store.streakDays();

    return Column(
      key: const ValueKey('me_week_checkin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本周打卡', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message: _tooltip(days[i]),
                    child: Column(
                      children: [
                        Text(
                          _labels[i],
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 6),
                        _DayDot(day: days[i], scheme: scheme),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '已连续 $streak 天',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.scheme});

  final CheckInDay day;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final status = day.status;
    final isMet = status == CheckInDayStatus.met;
    final isToday = status == CheckInDayStatus.todayProgress;
    final isMissed = status == CheckInDayStatus.missed;

    late final Color fill;
    late final Color border;
    late final double borderWidth;
    if (isMet) {
      fill = scheme.primary;
      border = scheme.primary;
      borderWidth = 0;
    } else if (isToday) {
      fill = scheme.primary.withValues(alpha: 0.18);
      border = scheme.primary;
      borderWidth = 2.5;
    } else if (isMissed) {
      fill = Colors.transparent;
      border = scheme.outline;
      borderWidth = 1.5;
    } else if (status == CheckInDayStatus.empty) {
      fill = Colors.transparent;
      border = scheme.outlineVariant;
      borderWidth = 1;
    } else {
      fill = scheme.outlineVariant.withValues(alpha: 0.25);
      border = scheme.outlineVariant.withValues(alpha: 0.4);
      borderWidth = 1;
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: borderWidth),
          ),
          child: isMet
              ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
              : (isToday
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null),
        ),
      ),
    );
  }
}
