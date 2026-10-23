import 'package:flutter_tts/flutter_tts.dart';

abstract class WordSpeaker {
  Future<void> setAccent(String languageCode);
  Future<void> speak(String text);
  Future<void> stop();
  void dispose();
}

class FlutterWordSpeaker implements WordSpeaker {
  FlutterWordSpeaker({String languageCode = 'en-US'}) {
    _language = languageCode;
    _tts = FlutterTts();
    _ready = _init();
  }

  late final FlutterTts _tts;
  late Future<void> _ready;
  late String _language;

  Future<void> _init() async {
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> setAccent(String languageCode) async {
    _language = languageCode;
    await _ready;
    await _tts.setLanguage(_language);
  }

  @override
  Future<void> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _ready;
    await _tts.setLanguage(_language);
    await _tts.stop();
    await _tts.speak(t);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _tts.stop();
  }
}

class FakeWordSpeaker implements WordSpeaker {
  final List<String> spoken = <String>[];
  String language = 'en-US';
  bool stopped = false;

  @override
  Future<void> setAccent(String languageCode) async {
    language = languageCode;
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  void dispose() {}
}