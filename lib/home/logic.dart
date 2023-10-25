

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../utils/audio_handler.dart';



class HomeLogic extends GetxController {
  final yt = YoutubeExplode();

  RxString videoId = ''.obs;
  RxBool isPlaying = false.obs;


  RxMap<String, Video> videoMap = <String, Video>{}.obs;

  RxList<String> titles = <String>[].obs;

  List<MediaItem> itemCollection = [];

  // late AudioHandler _audioHandler;

  late AudioPlayerHandlerImpl audioPlayerHandler;



  HomeLogic() {
    audioPlayerHandler = AudioPlayerHandlerImpl();
    AudioService.init(
        builder: () => audioPlayerHandler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.myapp.audio',
          androidNotificationChannelName: 'Audio Service Demo',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
    );
        // .then((value) => _audioHandler = value);
  }

  Future<void> extractPlaylist(String playlistId) async {
    var playlist = await yt.playlists.get(playlistId);
    var map = <String, Video>{};
    await for (var video in yt.playlists.getVideos(playlist.id)) {
      map[video.title] = video;
    }
    videoMap.value = map;
    titles.value = map.keys.toList();
    buildItemCollection().then((value) {
      if (kDebugMode) {
        print("itemCollection ready");
      }
      itemCollection = value;
    });
  }

  Future<MediaItem> getMediaItem(String title)async{
    final video = videoMap[title]!;
    var manifest = await yt.videos.streamsClient.getManifest(video.id.value);
    var audio = manifest.audioOnly.withHighestBitrate();
    return MediaItem(
      id: audio.url.toString(),
      title: title,
      duration: video.duration,
    );
  }

  Future<void> playAudioByTitle(String title) async {
    var item = await getMediaItem(title);
    audioPlayerHandler.playMediaItem(item);
    isPlaying.value = true;
  }

  Future<Uri> getAudioFromVideoId(VideoId videoId)async{
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var audio = manifest.audioOnly.first;
    return audio.url;
  }



  Future<void> playAllRandomly() async {


    audioPlayerHandler.setShuffleMode(AudioServiceShuffleMode.none);
    var itemMap = <String, MediaItem>{};
    var futures = videoMap.entries.map((entry) async {
      final item = await getMediaItem(entry.value.title);
      itemMap[entry.value.title] = item;
    }).toList();
    await Future.wait(futures);

    for (var key in videoMap.keys) {
      var item = itemMap[videoMap[key]!.title];
      if (item != null) {
        audioPlayerHandler.addQueueItem(item);
      }
    }

    audioPlayerHandler.play();
  }


  @override
  void dispose() {
    yt.close();
    super.dispose();
  }

  Future<List<MediaItem>> buildItemCollection() async {
    var itemMap = <String, MediaItem>{};
    List<MediaItem> tempCollection = [];
    var futures = videoMap.entries.map((entry) async {
      final item = await getMediaItem(entry.value.title);
      itemMap[entry.value.title] = item;
    }).toList();
    await Future.wait(futures);

    for (var key in videoMap.keys) {
      var item = itemMap[videoMap[key]!.title];
      if (item != null) {
        tempCollection.add(item);
      }
    }
    return tempCollection;
  }

  Future<void> playFromIndex(int index) async {



    if(itemCollection.isEmpty){

      return ;
    }



    if(audioPlayerHandler.playbackState.value.playing){
      await audioPlayerHandler.stop();
    }

    var reorderedCollection = [...itemCollection.sublist(index), ...itemCollection.sublist(0, index)];
    await audioPlayerHandler.updateQueue(reorderedCollection);
    await audioPlayerHandler.seekToIndex(Duration.zero, 0);
    audioPlayerHandler.play();

  }
}

