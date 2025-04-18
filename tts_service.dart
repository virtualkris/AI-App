import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  /// Initializes TTS engine with default settings.
  Future<void> initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  /// Speaks the given text aloud.
  Future<void> speak(String text) async {
    await _flutterTts.stop(); // Ensure nothing overlaps
    await _flutterTts.speak(text);
  }

  /// Stops any current speech.
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
