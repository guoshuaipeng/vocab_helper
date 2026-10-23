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
}
