import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/word.dart';
import '../services/progress_export.dart';
import '../services/progress_store.dart';
import '../services/unit_progress.dart';
import '../services/word_speaker.dart';
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
    required this.onStartDueReview,
    this.onPhotoVocab,
    this.speaker,
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
  /// Switch to learn · 认读 (R20 queue: due first). Used by due-review sheet.
  final VoidCallback onStartDueReview;
  final VoidCallback? onPhotoVocab;
  /// Optional TTS; when null, probes with a short-lived FlutterWordSpeaker.
  final WordSpeaker? speaker;

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  WordBookMeta? _book;
  bool _loadingBook = true;
  /// null = still probing; false = missing English voice pack.
  bool? _englishVoiceOk;

  @override
  void initState() {
    super.initState();
    _loadBook();
    _rollDay();
    _probeEnglishVoice();
  }

  Future<void> _probeEnglishVoice() async {
    WordSpeaker? owned;
    final speaker = widget.speaker ?? (owned = FlutterWordSpeaker(languageCode: widget.store.ttsAccent()));
    try {
      final ok = await speaker.englishVoiceAvailable();
      if (!mounted) return;
      setState(() => _englishVoiceOk = ok);
    } catch (_) {
      if (!mounted) return;
      setState(() => _englishVoiceOk = false);
    } finally {
      owned?.dispose();
    }
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


  Future<void> _exportProgress() async {
    final meta = _book;
    if (meta == null) return;
    WordBook book;
    try {
      book = await widget.repo.loadBook(meta.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载词书失败：$e')),
      );
      return;
    }
    final prefix = '${meta.id}-';
    final learnedIds = widget.store.learnedIds().where((id) => id.startsWith(prefix)).toSet();
    final wrongIds = widget.store.wrongIds().where((id) => id.startsWith(prefix)).toSet();
    final text = ProgressExport.build(
      bookTitle: book.title,
      date: DateTime.now(),
      totalCount: book.words.isNotEmpty ? book.words.length : book.wordCount,
      streak: widget.store.streakDays(),
      learned: ProgressExport.wordsInSet(book.words, learnedIds),
      wrong: ProgressExport.wordsInSet(book.words, wrongIds),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final previewLines = text.split('\n').take(12).join('\n');
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('导出进度', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        previewLines,
                        key: const ValueKey('export_preview'),
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('export_share'),
                          onPressed: () async {
                            await SharePlus.instance.share(ShareParams(text: text, subject: '单词小助手 · 进度导出'));
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('分享'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('export_copy'),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: text));
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制到剪贴板')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('复制全部'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  static const int _dueListCap = 40;

  Future<void> _openDueReviewSheet() async {
    final bookId = widget.store.selectedBookId();
    if (bookId == null || bookId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _DueReviewSheet(
          store: widget.store,
          repo: widget.repo,
          bookId: bookId,
          listCap: _dueListCap,
          onStartReview: () {
            Navigator.pop(ctx);
            widget.onStartDueReview();
          },
          onLearnNew: () {
            Navigator.pop(ctx);
            widget.onStartDueReview();
          },
        );
      },
    );
  }


  Future<void> _openUnitProgressSheet() async {
    final bookId = widget.store.selectedBookId();
    if (bookId == null || bookId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _UnitProgressSheet(
          store: widget.store,
          repo: widget.repo,
          bookId: bookId,
          bookTitle: _book?.title,
          onSelectUnit: (unit) async {
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            if (unit == null) {
              // 未分单元：现有筛选不支持「仅空 unit」→ 显示全部
              await widget.store.setUnitFilterForBook(bookId, null);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('这些词在「全部」里看'),
                  duration: Duration(milliseconds: 1600),
                ),
              );
            } else {
              await widget.store.setUnitFilterForBook(bookId, unit);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('已筛选 · $unit'),
                  duration: const Duration(milliseconds: 1200),
                ),
              );
            }
            widget.onRefresh();
            widget.onStartDueReview();
          },
        );
      },
    );
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
        cacheExtent: 4000,
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
                            TextButton.icon(
                              key: const ValueKey('export_progress'),
                              onPressed: _book == null ? null : _exportProgress,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: Text(_book == null
                                  ? '先选一本词书'
                                  : '导出本词书进度'),
                            ),
                            TextButton.icon(
                              key: const ValueKey('me_unit_progress'),
                              onPressed: _book == null ? null : _openUnitProgressSheet,
                              icon: const Icon(Icons.view_list_outlined),
                              label: Text(_book == null ? '先选一本词书' : '单元进度'),
                            ),
                            if (widget.onPhotoVocab != null)
                              FilledButton.tonalIcon(
                                key: const ValueKey('me_photo_vocab'),
                                onPressed: _book == null ? null : widget.onPhotoVocab,
                                icon: const Icon(Icons.document_scanner_outlined),
                                label: const Text('拍照加词'),
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
                  Text(
                    '$today / $goal',
                    key: const ValueKey('me_today_goal_count'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Row(
                    key: const ValueKey('me_today_goal_status'),
                    children: [
                      if (widget.store.todayGoalMet) ...[
                        Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          widget.store.todayGoalMet
                              ? '今日已完成 · $today/$goal'
                              : '再学 ${goal - today} 个就达标',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final id = widget.store.selectedBookId();
                      final hasBook = id != null && id.isNotEmpty;
                      final due = hasBook ? widget.store.dueReviewCountForBook(id) : 0;
                      final label = !hasBook
                          ? '先选一本词书'
                          : (due == 0 ? '暂无到期复习' : '待复习 $due');
                      final scheme = Theme.of(context).colorScheme;
                      final color = !hasBook || due == 0
                          ? scheme.onSurfaceVariant
                          : scheme.primary;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const ValueKey('me_due_review'),
                              onTap: hasBook ? _openDueReviewSheet : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: color,
                                              fontWeight: due > 0 ? FontWeight.w600 : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                    if (hasBook)
                                      Icon(
                                        Icons.chevron_right,
                                        color: color,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (hasBook)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '间隔会随认识变长',
                                key: const ValueKey('me_review_curve_hint'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      );
                    },
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
                  Text(
                    '学习页点喇叭时使用该口音（依赖系统已安装的语音包）。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_englishVoiceOk == false) ...[
                    const SizedBox(height: 8),
                    Text(
                      '还没有英文语音包。请到系统设置里安装英文语音，装好后喇叭和听音就能用。',
                      key: const ValueKey('me_accent_tts_hint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
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
                  Text(
                    '可看义 / 看词 / 听音 / 拼写 / 听写；答错仍进错词本。',
                    key: const ValueKey('me_quiz_card_subtitle'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                                key: const ValueKey('me_quiz_wrong_pool'),
                                onPressed: hasWrong ? widget.onQuizWrong : null,
                                icon: const Icon(Icons.fact_check_outlined),
                                label: const Text('去测错词'),
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
          _StatsSummaryCard(
            learned: widget.store.learnedCount(),
            todayNew: today,
            streak: widget.store.streakDays(),
          ),
        ],
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  const _StatsSummaryCard({
    required this.learned,
    required this.todayNew,
    required this.streak,
  });

  final int learned;
  final int todayNew;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('me_stats_summary'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                key: const ValueKey('me_stat_learned'),
                label: '已学单词',
                value: '$learned',
                scheme: scheme,
              ),
            ),
            Container(width: 1, height: 44, color: scheme.outlineVariant),
            Expanded(
              child: _StatCell(
                key: const ValueKey('me_stat_today'),
                label: '今日新学',
                value: '$todayNew',
                scheme: scheme,
              ),
            ),
            Container(width: 1, height: 44, color: scheme.outlineVariant),
            Expanded(
              child: _StatCell(
                key: const ValueKey('me_stat_streak'),
                label: '连续天数',
                value: '$streak',
                scheme: scheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    super.key,
    required this.label,
    required this.value,
    required this.scheme,
  });

  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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


class _DueReviewSheet extends StatefulWidget {
  const _DueReviewSheet({
    required this.store,
    required this.repo,
    required this.bookId,
    required this.listCap,
    required this.onStartReview,
    required this.onLearnNew,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String bookId;
  final int listCap;
  final VoidCallback onStartReview;
  final VoidCallback onLearnNew;

  @override
  State<_DueReviewSheet> createState() => _DueReviewSheetState();
}

class _DueReviewSheetState extends State<_DueReviewSheet> {
  bool _loading = true;
  List<Word> _words = const [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = widget.store.dueReviewEntriesForBook(widget.bookId);
    _total = entries.length;
    if (entries.isEmpty) {
      if (!mounted) return;
      setState(() {
        _words = const [];
        _loading = false;
      });
      return;
    }
    try {
      final book = await widget.repo.loadBook(widget.bookId);
      final byId = {for (final w in book.words) w.id: w};
      final paired = <({Word w, String at})>[];
      for (final e in entries) {
        final w = byId[e.id];
        if (w != null) paired.add((w: w, at: e.at));
      }
      paired.sort((a, b) {
        final c = a.at.compareTo(b.at);
        if (c != 0) return c;
        return a.w.word.toLowerCase().compareTo(b.w.word.toLowerCase());
      });
      final words = paired.map((e) => e.w).toList();
      if (!mounted) return;
      setState(() {
        _words = words;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _words = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    final listMax = maxH - 140;
    final shown = _words.length > widget.listCap ? _words.take(widget.listCap).toList() : _words;
    final more = _total > widget.listCap ? _total - widget.listCap : 0;

    Widget body;
    if (_loading) {
      body = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_words.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '暂无到期复习',
              key: const ValueKey('due_review_empty'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('due_review_learn_new'),
              onPressed: widget.onLearnNew,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('去学新词'),
              ),
            ),
          ],
        ),
      );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: listMax),
        child: ListView.separated(
          key: const ValueKey('due_review_list'),
          shrinkWrap: true,
          itemCount: shown.length + (more > 0 ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (more > 0 && i == shown.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '还有 $more 个，开始复习仍会全部入队',
                  key: const ValueKey('due_review_truncate'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            final w = shown[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              title: Text(
                w.word,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: (w.meaning.trim().isEmpty)
                  ? null
                  : Text(w.meaning, style: Theme.of(context).textTheme.bodyMedium),
              trailing: Text(
                '复习',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('到期复习', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            body,
            if (!_loading && _words.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('due_review_start'),
                onPressed: widget.onStartReview,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('开始复习'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _UnitProgressSheet extends StatefulWidget {
  const _UnitProgressSheet({
    required this.store,
    required this.repo,
    required this.bookId,
    required this.onSelectUnit,
    this.bookTitle,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String bookId;
  final String? bookTitle;
  /// null unit = 未分单元 → caller clears filter.
  final Future<void> Function(String? unit) onSelectUnit;

  @override
  State<_UnitProgressSheet> createState() => _UnitProgressSheetState();
}

class _UnitProgressSheetState extends State<_UnitProgressSheet> {
  bool _loading = true;
  UnitProgressSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final book = await widget.repo.loadBook(widget.bookId);
      final summary = buildUnitProgress(book: book, store: widget.store);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = const UnitProgressSummary(
          rows: [],
          learned: 0,
          total: 0,
          wrong: 0,
          hasAnyUnit: false,
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    final summary = _summary;

    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (summary == null || !summary.hasAnyUnit) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '这本词书还没有按单元划分',
              key: const ValueKey('unit_progress_empty'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH - 80),
        child: ListView.separated(
          key: const ValueKey('unit_progress_list'),
          shrinkWrap: true,
          itemCount: summary.rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final row = summary.rows[i];
            return ListTile(
              key: ValueKey('unit_progress_row_${row.unit}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minVerticalPadding: 12,
              title: Text(
                row.unit,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已学 ${row.learned}/${row.total}  ·  错 ${row.wrong}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: row.fraction,
                        minHeight: 3,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: row.isComplete
                  ? Text(
                      '满',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                          ),
                    )
                  : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              onTap: () => widget.onSelectUnit(row.isUngrouped ? null : row.unit),
            );
          },
        ),
      );
    }

    final short = widget.bookTitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('单元进度', style: Theme.of(context).textTheme.titleLarge),
            if (short != null && short.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                short,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (!_loading && summary != null && summary.hasAnyUnit) ...[
              const SizedBox(height: 8),
              Text(
                '已学 ${summary.learned}/${summary.total} · 错词 ${summary.wrong}',
                key: const ValueKey('unit_progress_summary'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

