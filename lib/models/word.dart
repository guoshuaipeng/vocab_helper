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

  Word copyWith({String? unit}) {
    return Word(
      id: id,
      word: word,
      meaning: meaning,
      phonetic: phonetic,
      example: example,
      unit: unit ?? this.unit,
    );
  }
}

class WordBookMeta {
  const WordBookMeta({
    required this.id,
    required this.file,
    required this.version,
    required this.grade,
    required this.title,
    this.wordCount = 0,
  });

  final String id;
  final String file;
  final String version;
  final String grade;
  final String title;
  final int wordCount;

  factory WordBookMeta.fromJson(Map<String, dynamic> json) {
    return WordBookMeta(
      id: json['id'] as String,
      file: json['file'] as String,
      version: json['version'] as String,
      grade: json['grade'] as String,
      title: json['title'] as String,
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
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
}