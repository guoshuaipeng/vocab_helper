import '../models/word.dart';

/// Builds UTF-8 plain-text progress export for one wordbook (R28).
class ProgressExport {
  ProgressExport._();

  static String build({
    required String bookTitle,
    required DateTime date,
    required int totalCount,
    required int streak,
    required List<Word> learned,
    required List<Word> wrong,
  }) {
    final learnedSorted = [...learned]..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    final wrongSorted = [...wrong]..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final buf = StringBuffer();
    buf.writeln('\u5355\u8bcd\u5c0f\u52a9\u624b \u00b7 \u8fdb\u5ea6\u5bfc\u51fa');
    buf.writeln('\u8bcd\u4e66\uff1a$bookTitle');
    buf.writeln('\u65e5\u671f\uff1a$y-$m-$d');
    buf.writeln('\u5df2\u5b66\uff1a${learnedSorted.length}/$totalCount');
    buf.writeln('\u9519\u8bcd\uff1a${wrongSorted.length}');
    buf.writeln('\u8fde\u7eed\u5b66\u4e60\uff1a$streak \u5929');
    buf.writeln();
    buf.writeln('\u3010\u5df2\u5b66\u5355\u8bcd\u3011');
    if (learnedSorted.isEmpty) {
      buf.writeln('\uff08\u6682\u65e0\uff09');
    } else {
      for (final w in learnedSorted) {
        buf.writeln('${w.word} \u2014 ${w.meaning}');
      }
    }
    buf.writeln();
    buf.writeln('\u3010\u9519\u8bcd\u3011');
    if (wrongSorted.isEmpty) {
      buf.writeln('\uff08\u6682\u65e0\uff09');
    } else {
      for (final w in wrongSorted) {
        buf.writeln('${w.word} \u2014 ${w.meaning}');
      }
    }
    return buf.toString();
  }

  /// Filter book words by id sets (ids use book prefix).
  static List<Word> wordsInSet(List<Word> bookWords, Set<String> ids) {
    return bookWords.where((w) => ids.contains(w.id)).toList();
  }
}
