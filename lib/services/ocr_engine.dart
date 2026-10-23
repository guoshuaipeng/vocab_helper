import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// On-device OCR abstraction (R37).
abstract class OcrEngine {
  /// Whether this engine can OCR an image path on the current platform.
  bool get supportsImageOcr;

  /// Recognize text from a local image file. Empty string if nothing found.
  Future<String> recognizeFile(String path);
}

/// iOS Apple Vision via MethodChannel. Compiles everywhere; only works on device.
class IosVisionOcrEngine implements OcrEngine {
  static const _channel = MethodChannel('com.vocab_helper/vision_ocr');

  @override
  bool get supportsImageOcr => !kIsWeb && Platform.isIOS;

  @override
  Future<String> recognizeFile(String path) async {
    if (!supportsImageOcr) {
      throw UnsupportedError('Vision OCR 仅支持 iOS 真机');
    }
    final result = await _channel.invokeMethod<String>('recognizeText', {
      'path': path,
    });
    return result ?? '';
  }
}

/// Desktop / test stub — always unsupported for images.
class StubOcrEngine implements OcrEngine {
  StubOcrEngine({this.message = '本机暂不支持图片 OCR，请用粘贴文字'});

  final String message;

  @override
  bool get supportsImageOcr => false;

  @override
  Future<String> recognizeFile(String path) async {
    throw UnsupportedError(message);
  }
}

OcrEngine createDefaultOcrEngine() {
  if (!kIsWeb && Platform.isIOS) return IosVisionOcrEngine();
  return StubOcrEngine();
}
