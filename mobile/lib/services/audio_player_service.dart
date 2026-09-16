import 'package:audioplayers/audioplayers.dart';

/// Plays back a locally-stored voice note file (see AudioRecorderService).
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  Future<void> play(String filePath) => _player.play(DeviceFileSource(filePath));

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
  }
}
