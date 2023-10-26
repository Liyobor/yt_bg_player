

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../utils/audio_handler.dart';



class HomeLogic extends GetxController {
  final yt = YoutubeExplode();

  RxString videoId = ''.obs;
  RxBool isPlaying = false.obs;


  RxMap<String, Video> videoMap = <String, Video>{}.obs;

  List<String> titles = <String>[];

  RxList<MediaItem> itemCollection = <MediaItem>[].obs;

  // late AudioHandler _audioHandler;

  late AudioPlayerHandlerImpl audioPlayerHandler;

  RxInt parseVideoProgress = 0.obs;
  RxBool isBuildingCollection = false.obs;



  HomeLogic() {
    audioPlayerHandler = AudioPlayerHandlerImpl();
    AudioService.init(
        builder: () => audioPlayerHandler,
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.myapp.audio',
          androidNotificationChannelName: 'Audio Service Demo',
          // androidNotificationOngoing: true,
          androidStopForegroundOnPause: false
        ),
    );
        // .then((value) => _audioHandler = value);
  }

  Future<void> extractPlaylist(String playlistId) async {
    audioPlayerHandler.updateQueue([]);
    itemCollection.clear();
    var playlist = await yt.playlists.get(playlistId);
    var map = <String, Video>{};
    await for (var video in yt.playlists.getVideos(playlist.id)) {
      map[video.title] = video;
    }
    videoMap.value = map;
    titles = map.keys.toList();
    buildItemCollection();
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

  Future<void> buildItemCollection() async {
    isBuildingCollection.value = true; // 设置为true，表示开始建构
    itemCollection.clear();
    for (var _ in videoMap.keys) {
      itemCollection.add(const MediaItem(id: 'temp', title: 'Loading...'));
    }

    // 創建一個 key_index map
    var keyIndexMap = <String, int>{};
    var i = 0;
    for (var key in videoMap.keys) {
      keyIndexMap[key] = i;
      i++;
    }

    var futures = videoMap.keys.map((key) async {
      final item = await getMediaItem(videoMap[key]!.title);
      int index = keyIndexMap[key]!;
      itemCollection[index] = item;
      parseVideoProgress.value++;
    }).toList();

    // 等待所有getMediaItem调用完成
    await Future.wait(futures);
    parseVideoProgress.value = 0;
    isBuildingCollection.value = false; // 设置为false，表示建构完成
  }


  Future<void> playFromIndex(int index) async {



    if(itemCollection.isEmpty||itemCollection[index].id=="temp"){
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

