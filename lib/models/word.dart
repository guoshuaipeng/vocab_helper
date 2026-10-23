class Word {
  const Word({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    this.example,
  });

  final String id;
  final String word;
  final String meaning;
  final String? phonetic;
  final String? example;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      phonetic: json['phonetic'] as String?,
      example: json['example'] as String?,
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
  });

  final String id;
  final String file;
  final String version;
  final String grade;
  final String title;

  factory WordBookMeta.fromJson(Map<String, dynamic> json) {
    return WordBookMeta(
      id: json['id'] as String,
      file: json['file'] as String,
      version: json['version'] as String,
      grade: json['grade'] as String,
      title: json['title'] as String,
    );
  }
}

class WordBook {
  const WordBook({
    required this.id,
    required this.version,
    required this.grade,
    required this.title,
    required this.source,
    required this.words,
  });

  final String id;
  final String version;
  final String grade;
  final String title;
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
      source: (json['source'] as String?) ?? '',
      words: list,
    );
  }
}