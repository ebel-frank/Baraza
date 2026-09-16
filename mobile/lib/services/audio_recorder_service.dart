import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Records the mediator's actual voice note to a real audio file on-device —
/// independent of speech-to-text (which only fills the description text).
/// The file stays local (see README "Known simplifications": voiceNoteRef
/// doesn't sync to the backend/another device, only case text does).
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> ensureReady() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> start() async {
    final ready = await ensureReady();
    if (!ready) return;
    final dir = await getApplicationDocumentsDirectory();
    final voiceNotesDir = Directory(p.join(dir.path, 'voice_notes'));
    if (!await voiceNotesDir.exists()) {
      await voiceNotesDir.create(recursive: true);
    }
    // WAV rather than AAC/m4a: Gemini's audio-understanding input accepts
    // audio/wav directly, whereas an MPEG-4-container m4a is not in its
    // supported MIME list.
    final path = p.join(voiceNotesDir.path, '${const Uuid().v4()}.wav');
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
    _currentPath = path;
  }

  /// Returns the recorded file's path, or null if nothing was recorded.
  Future<String?> stop() async {
    final path = await _recorder.stop();
    final result = path ?? _currentPath;
    _currentPath = null;
    return result;
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    _currentPath = null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
