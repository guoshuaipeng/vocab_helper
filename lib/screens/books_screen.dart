import 'package:flutter/material.dart';

import '../data/seed_words.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(defaultBookTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('$defaultBookDesc\n共 ${seedWords.length} 词'),
            ),
            trailing: const Icon(Icons.menu_book_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Text('更多词书后续轮次再加', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
