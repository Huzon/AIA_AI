import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

final sttServiceProvider = Provider((ref) => STTService());

class STTService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initSTT() async {
    return await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
  }

  void startListening(Function(String) onResult) {
    _speech.listen(onResult: (result) => onResult(result.recognizedWords));
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
