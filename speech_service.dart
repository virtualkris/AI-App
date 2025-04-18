import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  Future<bool> initSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) => print('🟡 onStatus: $status'),
      onError: (error) => print('🔴 onError: $error'),
    );
    print('✅ STT Initialized: $available');
    return available;
  }

  Future<void> startListening(Function(String) onResult) async {
    print('🎤 Start Listening...');
    await _speechToText.listen(
      onResult: (result) {
        print('🗣 Recognized: ${result.recognizedWords}');
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      listenMode: ListenMode.dictation,
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    print('🛑 Stop Listening');
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
