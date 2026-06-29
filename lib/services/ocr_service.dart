import 'package:flutter/services.dart';

class OcrService {
  static const _channel = MethodChannel('meomchit/ocr');

  Future<String> extractText(String imagePath) async {
    final text = await _channel.invokeMethod<String>('extractText', {
      'path': imagePath,
    });
    return text?.trim() ?? '';
  }

  Future<void> dispose() async {}
}
