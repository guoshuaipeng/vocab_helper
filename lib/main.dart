import 'package:flutter/material.dart';

import 'screens/books_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/me_screen.dart';
import 'screens/photo_vocab_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/setup_screen.dart';
import 'services/custom_word_overlay.dart';
import 'services/progress_store.dart';
import 'services/wordbook_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  final repo = WordbookRepository();
  repo.overlay = await CustomWordOverlay.open();
  runApp(VocabApp(store: store, repo: repo));
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key, required this.store, required this.repo});

  final ProgressStore store;
  final WordbookRepository repo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '单词小助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: RootGate(store: store, repo: repo),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key, required this.store, required this.repo});

  final ProgressStore store;
  final WordbookRepository repo;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ready = widget.store.hasSelectedBook;
  }

  void _onSetupDone() => setState(() => _ready = true);

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SetupScreen(store: widget.store, repo: widget.repo, onDone: _onSetupDone);
    }
    return HomeShell(
      store: widget.store,
      repo: widget.repo,
      onChangeBook: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SetupScreen(
              store: widget.store,
              repo: widget.repo,
              allowSkip: true,
              onDone: () {
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.store,
    required this.repo,
    required this.onChangeBook,
  });

  final ProgressStore store;
  final WordbookRepository repo;
  final VoidCallback onChangeBook;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _reviewWrongOnly = false;
  bool _reviewWrongUnitScoped = false;

  void _enterWrongReview({required bool unitScoped}) {
    setState(() {
      _reviewWrongOnly = true;
      _reviewWrongUnitScoped = unitScoped;
      _index = 0;
    });
  }

  void _learnNew() {
    setState(() {
      _reviewWrongOnly = false;
      _reviewWrongUnitScoped = false;
      _index = 0;
    });
  }

  Future<void> _openQuiz(QuizMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          store: widget.store,
          repo: widget.repo,
          mode: mode,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPhotoVocab() async {
    final id = widget.store.selectedBookId();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择词书')),
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoVocabScreen(
          store: widget.store,
          repo: widget.repo,
          bookId: id,
        ),
      ),
    );
    if (mounted && changed == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.store.selectedBookId();
    final pages = [
      LearnScreen(
        store: widget.store,
        repo: widget.repo,
        bookId: bookId,
        onNeedSetup: widget.onChangeBook,
        reviewWrongOnly: _reviewWrongOnly,
        reviewWrongUnitScoped: _reviewWrongUnitScoped,
        onLearnNew: _learnNew,
        onReviewWrongAll: () => _enterWrongReview(unitScoped: false),
        onStartQuiz: () {
          _learnNew();
          final id = widget.store.selectedBookId();
          final unit = id == null ? null : widget.store.unitFilterForBook(id);
          _openQuiz((unit != null && unit.isNotEmpty) ? QuizMode.unit : QuizMode.book);
        },
      ),
      BooksScreen(
        store: widget.store,
        repo: widget.repo,
        selectedBookId: bookId,
        onChangeBook: widget.onChangeBook,
        onBookSelected: () => setState(() {}),
      ),
      MeScreen(
        store: widget.store,
        repo: widget.repo,
        onRefresh: () => setState(() {}),
        onChangeBook: widget.onChangeBook,
        onReviewWrong: () => _enterWrongReview(unitScoped: false),
        onReviewWrongCurrentUnit: () => _enterWrongReview(unitScoped: true),
        onQuizBook: () => _openQuiz(QuizMode.book),
        onQuizUnit: () => _openQuiz(QuizMode.unit),
        onQuizWrong: () => _openQuiz(QuizMode.wrong),
        onStartDueReview: _learnNew,
        onPhotoVocab: _openPhotoVocab,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('单词小助手'),
        actions: [
          if (_index == 0) ...[
            IconButton(
              key: const ValueKey('nav_photo_vocab'),
              tooltip: '拍照加词',
              onPressed: _openPhotoVocab,
              icon: const Icon(Icons.document_scanner_outlined),
            ),
            IconButton(
              tooltip: '自测本单元',
              onPressed: () {
                final id = widget.store.selectedBookId();
                final unit = id == null ? null : widget.store.unitFilterForBook(id);
                _openQuiz((unit != null && unit.isNotEmpty) ? QuizMode.unit : QuizMode.book);
              },
              icon: const Icon(Icons.quiz_outlined),
            ),
          ],
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          if (i != 0) {
            _reviewWrongOnly = false;
            _reviewWrongUnitScoped = false;
          }
          _index = i;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: '学习'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '词书'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
