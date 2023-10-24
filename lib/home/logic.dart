
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../utils/audio_handler.dart';



class HomeLogic extends GetxController {
  final yt = YoutubeExplode();
  // final player = AudioPlayer();
  late final AudioPlayerHandler audioHandler;
  RxString videoId = ''.obs;
  RxBool isPlaying = false.obs;


  RxMap<String, String> videoIdMap = <String, String>{}.obs;
  RxList<String> titles = <String>[].obs;

  HomeLogic() {
    audioHandler = AudioPlayerHandler();
    AudioService.init(
        builder: () => audioHandler,
        config:AudioServiceConfig(
          androidNotificationChannelId : "",
          androidNotificationChannelName: 'Music playback',
        ));
  }

  Future<void> extractPlaylist(String playlistId) async {

    var playlist = await yt.playlists.get(playlistId);
    var map = <String, String>{};
    await for (var video in yt.playlists.getVideos(playlist.id)) {
      map[video.title] = video.id.value;
    }
    videoIdMap.value = map;
    titles.value = map.keys.toList();

  }

  Future<Uri> getAudioFromVideoId(String videoId)async{
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var audio = manifest.audioOnly.first;
    return audio.url;
  }

  Future<void> playAudio(String url) async {
    await audioHandler.setUrl(url);
    audioHandler.play();
    isPlaying.value = true;
  }

  @override
  void dispose() {
    yt.close();
    // player.dispose();
    // audioHandler.dispose();
    super.dispose();
  }
}

