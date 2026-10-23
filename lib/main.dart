import 'package:flutter/material.dart';

import 'screens/books_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/me_screen.dart';
import 'services/progress_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  runApp(VocabApp(store: store));
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '单词小助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeShell(store: store),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final ProgressStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LearnScreen(store: widget.store),
      const BooksScreen(),
      MeScreen(store: widget.store, onRefresh: () => setState(() {})),
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
