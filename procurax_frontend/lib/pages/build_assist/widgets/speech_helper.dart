import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechHelper {
  final stt.SpeechToText _speech;
  bool _isAvailable = false;
  bool _isListening = false;

  SpeechHelper() : _speech = stt.SpeechToText();

  Future<void> init() async {
    try {
      _isAvailable = await _speech.initialize();
    } catch (e) {
      debugPrint('SpeechHelper init error: $e');
      _isAvailable = false;
    }
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
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }
}
