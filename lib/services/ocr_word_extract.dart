import '../models/word.dart';

/// Match of an OCR token against the current wordbook.
enum OcrMatchKind {
  /// Exact spelling (case-insensitive) already in book.
  inBook,
  /// Not in book — needs meaning before learning.
  newWord,
}

/// One candidate row on the confirm screen.
class OcrWordCandidate {
  OcrWordCandidate({
    required this.spelling,
    required this.meaning,
    required this.kind,
    this.bookWordId,
    this.selected = true,
  });

  String spelling;
  String meaning;
  OcrMatchKind kind;
  String? bookWordId;
  bool selected;

  bool get canLearn =>
      spelling.trim().isNotEmpty && meaning.trim().isNotEmpty;
}

/// Ultra-common tokens we skip (not useful as vocab cards).
const _kStop = {
  'a', 'an', 'the', 'and', 'or', 'but', 'to', 'of', 'in', 'on', 'at', 'for',
  'is', 'are', 'was', 'were', 'be', 'been', 'am', 'i', 'you', 'he', 'she',
  'it', 'we', 'they', 'my', 'your', 'his', 'her', 'its', 'our', 'their',
  'this', 'that', 'these', 'those', 'with', 'from', 'as', 'by', 'not',
  'do', 'does', 'did', 'have', 'has', 'had', 'will', 'would', 'can', 'could',
  'should', 'may', 'might', 'must', 'shall', 'if', 'so', 'than', 'then',
  'too', 'very', 'just', 'also', 'into', 'about', 'up', 'out', 'what',
  'when', 'where', 'who', 'how', 'which', 'there', 'here', 'unit', 'page',
};

final _tokenRe = RegExp(r"[A-Za-z][A-Za-z'\\-]{0,30}[A-Za-z]|[A-Za-z]{2,}");

/// Extract unique Latin tokens from raw OCR / pasted text.
List<String> extractEnglishTokens(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final m in _tokenRe.allMatches(raw)) {
    var t = m.group(0)!;
    t = t.replaceAll(RegExp(r'^-+|-+$'), '');
    if (t.length < 2) continue;
    if (RegExp(r'^[0-9]+$').hasMatch(t)) continue;
    final lower = t.toLowerCase();
    if (_kStop.contains(lower)) continue;
    if (seen.contains(lower)) continue;
    seen.add(lower);
    out.add(t);
  }
  return out;
}

/// Build confirm-list candidates; [bookWords] is current book (base + overlay OK).
List<OcrWordCandidate> matchTokensToBook(
  List<String> tokens,
  List<Word> bookWords,
) {
  final byLower = <String, Word>{};
  for (final w in bookWords) {
    byLower.putIfAbsent(w.word.toLowerCase(), () => w);
  }
  final out = <OcrWordCandidate>[];
  for (final t in tokens) {
    final hit = byLower[t.toLowerCase()];
    if (hit != null) {
      out.add(
        OcrWordCandidate(
          spelling: hit.word,
          meaning: hit.meaning,
          kind: OcrMatchKind.inBook,
          bookWordId: hit.id,
          selected: false,
        ),
      );
    } else {
      out.add(
        OcrWordCandidate(
          spelling: t,
          meaning: '',
          kind: OcrMatchKind.newWord,
          selected: true,
        ),
      );
    }
  }
  return out;
}
