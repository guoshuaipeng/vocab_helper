class Word {
  const Word({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    this.example,
    this.unit,
  });

  final String id;
  final String word;
  final String meaning;
  final String? phonetic;
  final String? example;
  final String? unit;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      phonetic: json['phonetic'] as String?,
      example: json['example'] as String?,
      unit: json['unit'] as String?,
    );
  }

  Word copyWith({
    String? id,
    String? word,
    String? meaning,
    String? phonetic,
    String? example,
    String? unit,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      phonetic: phonetic ?? this.phonetic,
      example: example ?? this.example,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        if (phonetic != null) 'phonetic': phonetic,
        if (example != null) 'example': example,
        if (unit != null) 'unit': unit,
      };
}

class WordBookMeta {
  const WordBookMeta({
    required this.id,
    required this.file,
    required this.version,
    required this.grade,
    required this.title,
    this.wordCount = 0,
    this.sourceLabel = '',
  });

  final String id;
  final String file;
  final String version;
  final String grade;
  final String title;
  final int wordCount;
  /// Short badge for list cards, e.g. 扩充词表.
  final String sourceLabel;

  factory WordBookMeta.fromJson(Map<String, dynamic> json) {
    return WordBookMeta(
      id: json['id'] as String,
      file: json['file'] as String,
      version: json['version'] as String,
      grade: json['grade'] as String,
      title: json['title'] as String,
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      sourceLabel: (json['sourceLabel'] as String?) ?? '',
    );
  }
}

class WordBook {
  const WordBook({
    required this.id,
    required this.version,
    required this.grade,
    required this.title,
    this.wordCount = 0,
    required this.source,
    required this.words,
  });

  final String id;
  final String version;
  final String grade;
  final String title;
  final int wordCount;
  final String source;
  final List<Word> words;

  factory WordBook.fromJson(Map<String, dynamic> json) {
    final list = (json['words'] as List<dynamic>)
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList();
    return WordBook(
      id: json['id'] as String,
      version: json['version'] as String,
      grade: json['grade'] as String,
      title: json['title'] as String,
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      source: (json['source'] as String?) ?? '',
      words: list,
    );
  }

  /// Ensure every word has a unit label. Missing units are filled as 第N组 (15 words each).
  WordBook withUnits({int chunkSize = 15}) {
    final hasAny = words.any((w) => (w.unit ?? '').isNotEmpty);
    if (hasAny) {
      return WordBook(
        id: id,
        version: version,
        grade: grade,
        title: title,
        wordCount: wordCount,
        source: source,
        words: [
          for (var i = 0; i < words.length; i++)
            (words[i].unit ?? '').isNotEmpty
                ? words[i]
                : words[i].copyWith(unit: '第${(i ~/ chunkSize) + 1}组'),
        ],
      );
    }
    return WordBook(
      id: id,
      version: version,
      grade: grade,
      title: title,
      wordCount: wordCount,
      source: source,
      words: [
        for (var i = 0; i < words.length; i++)
          words[i].copyWith(unit: '第${(i ~/ chunkSize) + 1}组'),
      ],
    );
  }

  List<String> unitNames() {
    final seen = <String>{};
    final out = <String>[];
    for (final w in words) {
      final u = w.unit ?? '';
      if (u.isEmpty || seen.contains(u)) continue;
      seen.add(u);
      out.add(u);
    }
    return out;
  }

  /// Append [extra] words whose id / spelling are not already present.
  WordBook mergedWith(List<Word> extra) {
    if (extra.isEmpty) return this;
    final ids = words.map((w) => w.id).toSet();
    final spells = {for (final w in words) w.word.toLowerCase()};
    final added = <Word>[];
    for (final w in extra) {
      if (ids.contains(w.id)) continue;
      if (spells.contains(w.word.toLowerCase())) continue;
      added.add(w);
      ids.add(w.id);
      spells.add(w.word.toLowerCase());
    }
    if (added.isEmpty) return this;
    final all = [...words, ...added];
    return WordBook(
      id: id,
      version: version,
      grade: grade,
      title: title,
      wordCount: all.length,
      source: source,
      words: all,
    );
  }
}