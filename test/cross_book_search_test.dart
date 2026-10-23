import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/cross_book_search.dart';

WordBookMeta meta({
  required String id,
  String version = '人教版PEP',
  String grade = '三年级',
  String? title,
}) =>
    WordBookMeta(
      id: id,
      file: '$id.json',
      version: version,
      grade: grade,
      title: title ?? id,
      wordCount: 2,
    );

WordBook book(String id, List<Word> words, {String version = '人教版PEP', String grade = '三年级'}) =>
    WordBook(
      id: id,
      version: version,
      grade: grade,
      title: id,
      wordCount: words.length,
      source: 'test',
      words: words,
    );

void main() {
  group('CrossBookSearchIndex', () {
    late CrossBookSearchIndex index;
    late List<WordBookMeta> catalog;
    late List<WordBook> books;

    setUp(() {
      index = CrossBookSearchIndex();
      catalog = [
        meta(id: 'a', version: '人教版PEP', grade: '三年级'),
        meta(id: 'b', version: '外研版', grade: '三年级'),
        meta(id: 'c', version: '人教版PEP', grade: '四年级'),
      ];
      books = [
        book('a', const [
          Word(id: 'a1', word: 'Apple', meaning: '苹果'),
          Word(id: 'a2', word: 'cat', meaning: '猫'),
        ]),
        book('b', const [
          Word(id: 'b1', word: 'apple', meaning: '苹果'),
          Word(id: 'b2', word: 'dog', meaning: '狗'),
        ], version: '外研版'),
        book('c', const [
          Word(id: 'c1', word: 'Banana', meaning: '香蕉'),
          Word(id: 'c2', word: 'apple pie', meaning: '苹果派'),
        ], grade: '四年级'),
      ];
      index.replaceWithBooks(books, catalog);
    });

    test('english case-insensitive substring', () {
      final hits = index.query('APP');
      expect(hits.map((h) => h.word.word.toLowerCase()).toSet(), containsAll(['apple', 'apple pie']));
    });

    test('chinese meaning substring', () {
      final hits = index.query('苹果');
      expect(hits.length, greaterThanOrEqualTo(2));
      expect(hits.every((h) => h.word.meaning.contains('苹果')), isTrue);
    });

    test('stable order: current book first, then version/grade/word/bookId', () {
      final hits = index.query('apple', currentBookId: 'b');
      expect(hits.first.meta.id, 'b');
      // remaining sorted by version then grade then word then id
      final rest = hits.skip(1).toList();
      for (var i = 1; i < rest.length; i++) {
        final prev = rest[i - 1];
        final cur = rest[i];
        final cmpVersion = prev.meta.version.compareTo(cur.meta.version);
        if (cmpVersion != 0) {
          expect(cmpVersion, lessThan(0));
          continue;
        }
        final cmpGrade = prev.meta.grade.compareTo(cur.meta.grade);
        if (cmpGrade != 0) {
          expect(cmpGrade, lessThan(0));
          continue;
        }
        final cmpWord = prev.word.word.toLowerCase().compareTo(cur.word.word.toLowerCase());
        if (cmpWord != 0) {
          expect(cmpWord, lessThanOrEqualTo(0));
          continue;
        }
        expect(prev.meta.id.compareTo(cur.meta.id), lessThanOrEqualTo(0));
      }
    });

    test('truncates at 40', () {
      final manyWords = [
        for (var i = 0; i < 50; i++) Word(id: 'x$i', word: 'zoom$i', meaning: '测$i'),
      ];
      final big = book('big', manyWords);
      final bigMeta = meta(id: 'big', title: 'big');
      index.replaceWithBooks([big], [bigMeta]);
      final hits = index.query('zoom', limit: 40);
      expect(hits.length, 40);
    });

    test('empty query returns empty', () {
      expect(index.query('   '), isEmpty);
    });

    test('build skips failed books and still becomes ready', () async {
      final idx = CrossBookSearchIndex();
      await idx.build(
        catalog: catalog,
        loadBook: (m) async {
          if (m.id == 'b') throw StateError('fail');
          return books.firstWhere((b) => b.id == m.id);
        },
      );
      expect(idx.isReady, isTrue);
      final hits = idx.query('apple');
      expect(hits.any((h) => h.meta.id == 'b'), isFalse);
      expect(hits.any((h) => h.meta.id == 'a'), isTrue);
    });

    test('superseded build does not clobber newer generation', () async {
      final idx = CrossBookSearchIndex();
      var releaseFirst = false;
      final first = idx.build(
        catalog: catalog,
        loadBook: (m) async {
          while (!releaseFirst) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          return books.firstWhere((b) => b.id == m.id);
        },
      );
      // Start second build immediately (bumps generation).
      final second = idx.build(
        catalog: [catalog.first],
        loadBook: (m) async => books.firstWhere((b) => b.id == m.id),
      );
      await second;
      expect(idx.isReady, isTrue);
      expect(idx.entryCount, 2); // only book a
      releaseFirst = true;
      await first;
      // First must not overwrite second.
      expect(idx.entryCount, 2);
      expect(idx.query('apple').every((h) => h.meta.id == 'a'), isTrue);
    });

    test('query before ready returns empty', () {
      final idx = CrossBookSearchIndex();
      expect(idx.isReady, isFalse);
      expect(idx.query('apple'), isEmpty);
    });
  });
}
