import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum SpeechLanguage { english, swahili }

extension SpeechLanguageLocale on SpeechLanguage {
  /// Locale IDs as reported by the on-device speech recognizer. Swahili support
  /// depends on the phone's installed Google/OEM speech-recognition language
  /// packs — if `sw-KE` isn't available, fall back to English in the picker.
  String get localeId => switch (this) {
        SpeechLanguage.english => 'en-US',
        SpeechLanguage.swahili => 'sw-KE',
      };

  String get label => switch (this) {
        SpeechLanguage.english => 'English',
        SpeechLanguage.swahili => 'Kiswahili',
      };
}

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  Future<bool> ensureReady() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;
    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required SpeechLanguage language,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ready = await ensureReady();
    if (!ready) return;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        localeId: language.localeId,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> stop() => _speech.stop();
}
