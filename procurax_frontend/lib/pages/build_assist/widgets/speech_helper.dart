import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechHelper {
  stt.SpeechToText _speech;
  bool _isAvailable = false;
  bool _isListening = false;

  SpeechHelper() : _speech = stt.SpeechToText();

  Future<void> init() async {
    _isAvailable = await _speech.initialize();
  }

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  void startListening(Function(String) onResult) {
    _isListening = true;
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
      cancelOnError: true,
      partialResults: true,
    );
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }
}
