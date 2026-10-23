import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/word.dart';
import '../services/custom_word_overlay.dart';
import '../services/ocr_engine.dart';
import '../services/ocr_word_extract.dart';
import '../services/progress_store.dart';
import '../services/wordbook_repository.dart';

/// R37: photo / paste → OCR tokens → confirm → unit → overlay.
class PhotoVocabScreen extends StatefulWidget {
  const PhotoVocabScreen({
    super.key,
    required this.store,
    required this.repo,
    required this.bookId,
    this.ocrEngine,
    this.initialCandidates,
    this.skipSourceStep = false,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final String bookId;
  final OcrEngine? ocrEngine;

  /// Shot / test hook: jump straight to confirm list.
  final List<OcrWordCandidate>? initialCandidates;
  final bool skipSourceStep;

  @override
  State<PhotoVocabScreen> createState() => _PhotoVocabScreenState();
}

enum _Step { source, loading, confirm, done }

class _PhotoVocabScreenState extends State<PhotoVocabScreen> {
  late final OcrEngine _ocr;
  _Step _step = _Step.source;
  List<OcrWordCandidate> _candidates = [];
  String? _error;
  WordBook? _book;
  String? _unit;
  final _newUnitCtrl = TextEditingController();
  bool _creatingUnit = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ocr = widget.ocrEngine ?? createDefaultOcrEngine();
    if (widget.initialCandidates != null) {
      _candidates = widget.initialCandidates!;
      _step = _Step.confirm;
    } else if (widget.skipSourceStep) {
      _step = _Step.confirm;
    }
    _bootBook();
  }

  @override
  void dispose() {
    _newUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootBook() async {
    try {
      final book = await widget.repo.loadBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _book = book;
        _unit = widget.store.unitFilterForBook(widget.bookId) ??
            (book.unitNames().isNotEmpty ? book.unitNames().first : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '加载词书失败');
    }
  }

  bool get _isIos => !kIsWeb && Platform.isIOS;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _step = _Step.loading;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        setState(() => _step = _Step.source);
        return;
      }
      if (!_ocr.supportsImageOcr) {
        setState(() {
          _step = _Step.source;
          _error = _isIos
              ? 'Vision 未就绪，请用真机或改粘贴文字'
              : '图片 OCR 仅 iOS 真机；本机请用「粘贴文字」';
        });
        return;
      }
      final text = await _ocr.recognizeFile(file.path);
      await _applyRawText(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.source;
        _error = e is UnsupportedError ? e.message : '识别失败，可改粘贴文字';
      });
    }
  }

  Future<void> _pasteText() async {
    final ctrl = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴课文文字'),
        content: TextField(
          key: const ValueKey('ocr_paste_field'),
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '把英文段落贴在这里…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('抽取单词'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (raw == null) return;
    setState(() {
      _error = null;
      _step = _Step.loading;
    });
    await _applyRawText(raw);
  }

  Future<void> _applyRawText(String raw) async {
    final book = _book ?? await widget.repo.loadBook(widget.bookId);
    final tokens = extractEnglishTokens(raw);
    final cands = matchTokensToBook(tokens, book.words);
    if (!mounted) return;
    if (cands.isEmpty) {
      setState(() {
        _step = _Step.source;
        _error = '没有识别到英文单词，换一页或粘贴文字试试';
      });
      return;
    }
    setState(() {
      _book = book;
      _candidates = cands;
      _step = _Step.confirm;
    });
  }

  Future<void> _editCandidate(int index) async {
    final c = _candidates[index];
    final spell = TextEditingController(text: c.spelling);
    final mean = TextEditingController(text: c.meaning);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('改词 / 补义'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: spell,
              decoration: const InputDecoration(labelText: '英文'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: mean,
              decoration: const InputDecoration(labelText: '中文义（必填才能学）'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        c.spelling = spell.text.trim();
        c.meaning = mean.text.trim();
      });
    }
    spell.dispose();
    mean.dispose();
  }

  Future<void> _confirmJoin() async {
    final selected = _candidates.where((c) => c.selected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先勾选要加入的词')),
      );
      return;
    }
    final bad = selected.where((c) => !c.canLearn).toList();
    if (bad.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bad.length} 个词缺中文义，点进去补一下')),
      );
      return;
    }
    var unit = _unit?.trim() ?? '';
    if (_creatingUnit) {
      unit = _newUnitCtrl.text.trim();
    }
    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择或新建单元')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final overlay = widget.repo.overlay ?? await CustomWordOverlay.open();
      widget.repo.overlay = overlay;
      final toAdd = <Word>[];
      for (final c in selected) {
        if (c.kind == OcrMatchKind.inBook) {
          // Re-unit as a custom copy only if user explicitly selected in-book word.
          toAdd.add(
            Word(
              id: CustomWordOverlay.newId(widget.bookId, c.spelling),
              word: c.spelling,
              meaning: c.meaning,
              unit: unit,
            ),
          );
        } else {
          toAdd.add(
            Word(
              id: CustomWordOverlay.newId(widget.bookId, c.spelling),
              word: c.spelling,
              meaning: c.meaning,
              unit: unit,
            ),
          );
        }
      }
      // Skip duplicates already in overlay/base with same spelling — overlay handles.
      final added = await overlay.addWords(widget.bookId, toAdd);
      await widget.store.setUnitFilterForBook(widget.bookId, unit);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _step = _Step.done;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加入 $unit · $added 个词')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，再试一次')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照加词'),
        actions: [
          if (_step == _Step.confirm)
            TextButton(
              onPressed: () => setState(() {
                _step = _Step.source;
                _candidates = [];
              }),
              child: const Text('重来'),
            ),
        ],
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    switch (_step) {
      case _Step.source:
        return _sourceBody(context);
      case _Step.loading:
        return const Center(child: CircularProgressIndicator());
      case _Step.confirm:
        return _confirmBody(context);
      case _Step.done:
        return _doneBody(context);
    }
  }

  Widget _sourceBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('photo_vocab_source'),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '拍课本一页，抽出英文词；确认后再选单元加入学习。识别只在本机，不上传。',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('photo_vocab_camera'),
          onPressed: _isIos ? () => _pick(ImageSource.camera) : null,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(_isIos ? '拍照识别' : '拍照识别（需 iPhone）'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('photo_vocab_gallery'),
          onPressed: () => _pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('从相册选图'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('photo_vocab_paste'),
          onPressed: _pasteText,
          icon: const Icon(Icons.content_paste),
          label: const Text('粘贴文字抽取'),
        ),
        const SizedBox(height: 24),
        Text(
          _isIos
              ? 'iOS 使用系统 Vision 端侧识字；请在真机验证相机与 OCR。'
              : 'Windows / Android 本轮：可用「粘贴文字」走完整加词流程；图片 OCR 后置。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _confirmBody(BuildContext context) {
    final units = _book?.unitNames() ?? const <String>[];
    final scheme = Theme.of(context).colorScheme;
    final selectedCount = _candidates.where((c) => c.selected).length;

    return Column(
      key: const ValueKey('photo_vocab_confirm'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '勾选要学的词 · 已选 $selectedCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  for (final c in _candidates) {
                    c.selected = c.kind == OcrMatchKind.newWord && c.canLearn
                        ? true
                        : c.selected;
                  }
                }),
                child: const Text('新词全选'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: _candidates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final c = _candidates[i];
              final badge = c.kind == OcrMatchKind.inBook ? '已在书' : '新词';
              final badgeColor = c.kind == OcrMatchKind.inBook
                  ? scheme.secondaryContainer
                  : scheme.primaryContainer;
              return Card(
                key: ValueKey('ocr_cand_$i'),
                child: CheckboxListTile(
                  value: c.selected,
                  onChanged: (v) => setState(() => c.selected = v ?? false),
                  title: Text(
                    c.spelling,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    c.meaning.isEmpty ? '点右侧编辑补中文义' : c.meaning,
                    style: TextStyle(
                      color: c.meaning.isEmpty ? scheme.error : null,
                    ),
                  ),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 12)),
                      ),
                      IconButton(
                        tooltip: '编辑',
                        onPressed: () => _editCandidate(i),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ),
        Material(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('放到哪个单元？', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (!_creatingUnit) ...[
                  DropdownButtonFormField<String>(
                    key: const ValueKey('photo_vocab_unit'),
                    // ignore: deprecated_member_use
                    value: (_unit != null && units.contains(_unit)) ? _unit : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final u in units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => _unit = v),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('photo_vocab_new_unit'),
                      onPressed: () => setState(() => _creatingUnit = true),
                      child: const Text('新建单元'),
                    ),
                  ),
                ] else ...[
                  TextField(
                    key: const ValueKey('photo_vocab_new_unit_field'),
                    controller: _newUnitCtrl,
                    decoration: const InputDecoration(
                      labelText: '新单元名，如 Unit 9 / 我的拍照',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _creatingUnit = false),
                      child: const Text('改选已有单元'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey('photo_vocab_join'),
                  onPressed: _saving ? null : _confirmJoin,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_saving ? '加入中…' : '确认加入'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _doneBody(BuildContext context) {
    return Center(
      key: const ValueKey('photo_vocab_done'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('已加入学习池', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('回学习页即可按该单元刷卡'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('回到学习'),
            ),
          ],
        ),
      ),
    );
  }
}
