import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {


  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.completed) {
        stop();
      } else if (processingState == ProcessingState.ready && !playing) {
        pause();
      } else if (processingState == ProcessingState.buffering || playing) {
        play();
      }
    });
  }

  @override
  Future<void> play() async {
    _player.play();
  }

  @override
  Future<void> pause() async {
    _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }


}
