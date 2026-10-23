import '../models/word.dart';
import 'progress_store.dart';

/// Label for words with empty/missing unit (R30).
const kUngroupedUnitLabel = '未分单元';

class UnitProgressRow {
  const UnitProgressRow({
    required this.unit,
    required this.learned,
    required this.total,
    required this.wrong,
    this.isUngrouped = false,
  });

  final String unit;
  final int learned;
  final int total;
  final int wrong;
  final bool isUngrouped;

  double get fraction => total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0);

  bool get isComplete => total > 0 && learned >= total;
}

class UnitProgressSummary {
  const UnitProgressSummary({
    required this.rows,
    required this.learned,
    required this.total,
    required this.wrong,
    required this.hasAnyUnit,
  });

  final List<UnitProgressRow> rows;
  final int learned;
  final int total;
  final int wrong;

  /// False when every word lacks a unit label (empty-state sheet).
  final bool hasAnyUnit;
}

/// Natural-ish unit order: extract first integer; else lexicographic; 未分单元 last.
int compareUnitNames(String a, String b) {
  if (a == kUngroupedUnitLabel && b != kUngroupedUnitLabel) return 1;
  if (b == kUngroupedUnitLabel && a != kUngroupedUnitLabel) return -1;
  final na = _firstInt(a);
  final nb = _firstInt(b);
  if (na != null && nb != null && na != nb) return na.compareTo(nb);
  if (na != null && nb == null) return -1;
  if (na == null && nb != null) return 1;
  return a.compareTo(b);
}

int? _firstInt(String s) {
  final m = RegExp(r'\d+').firstMatch(s);
  if (m == null) return null;
  return int.tryParse(m.group(0)!);
}

/// Aggregate learned / total / wrong per unit for [book] using [store].
UnitProgressSummary buildUnitProgress({
  required WordBook book,
  required ProgressStore store,
}) {
  final learned = store.learnedIds();
  final wrong = store.wrongIds();
  final totals = <String, int>{};
  final learnedCounts = <String, int>{};
  final wrongCounts = <String, int>{};
  var hasAnyUnit = false;

  for (final w in book.words) {
    final raw = (w.unit ?? '').trim();
    final key = raw.isEmpty ? kUngroupedUnitLabel : raw;
    if (raw.isNotEmpty) hasAnyUnit = true;
    totals[key] = (totals[key] ?? 0) + 1;
    if (learned.contains(w.id)) {
      learnedCounts[key] = (learnedCounts[key] ?? 0) + 1;
    }
    if (wrong.contains(w.id)) {
      wrongCounts[key] = (wrongCounts[key] ?? 0) + 1;
    }
  }

  final keys = totals.keys.toList()..sort(compareUnitNames);
  final rows = <UnitProgressRow>[
    for (final k in keys)
      if ((totals[k] ?? 0) > 0)
        UnitProgressRow(
          unit: k,
          learned: learnedCounts[k] ?? 0,
          total: totals[k]!,
          wrong: wrongCounts[k] ?? 0,
          isUngrouped: k == kUngroupedUnitLabel,
        ),
  ];

  return UnitProgressSummary(
    rows: hasAnyUnit ? rows : const [],
    learned: learnedCounts.values.fold(0, (a, b) => a + b),
    total: book.words.length,
    wrong: wrongCounts.values.fold(0, (a, b) => a + b),
    hasAnyUnit: hasAnyUnit,
  );
}
