import 'package:flutter/material.dart';

import 'screens/books_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/me_screen.dart';
import 'screens/setup_screen.dart';
import 'services/progress_store.dart';
import 'services/wordbook_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  final repo = WordbookRepository();
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

  @override
  Widget build(BuildContext context) {
    final bookId = widget.store.selectedBookId();
    final pages = [
      LearnScreen(
        store: widget.store,
        repo: widget.repo,
        bookId: bookId,
        onNeedSetup: widget.onChangeBook,
      ),
      BooksScreen(
        repo: widget.repo,
        selectedBookId: bookId,
        onChangeBook: widget.onChangeBook,
      ),
      MeScreen(store: widget.store, repo: widget.repo, onRefresh: () => setState(() {}), onChangeBook: widget.onChangeBook),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('单词小助手')),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: '学习'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '词书'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}