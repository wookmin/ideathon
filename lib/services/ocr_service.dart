import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<String> extractText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(input);
    return recognizedText.text.trim();
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
