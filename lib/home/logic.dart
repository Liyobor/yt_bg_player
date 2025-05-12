

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:pool/pool.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../main.dart';
import '../utils/audio_handler.dart';

enum LoopMode { off, on, single }

class HomeLogic extends GetxController {
  final yt = YoutubeExplode();

  RxString videoId = ''.obs;
  RxBool isPlaying = false.obs;


  RxMap<String, Video> videoMap = <String, Video>{}.obs;

  List<String> titles = <String>[];

  RxList<MediaItem> itemCollection = <MediaItem>[].obs;

  late AudioHandler _audioHandler;

  late AudioPlayerHandlerImpl audioPlayerHandler;

  RxInt parseVideoProgress = 0.obs;
  RxBool isBuildingCollection = false.obs;

  var shuffleActive = false.obs;
  var loopMode = LoopMode.off.obs;
  var currentMediaItem = const MediaItem(id: 'temp', title: 'Playing Nothing').obs;
  void initPlayer() {

    audioPlayerHandler = AudioPlayerHandlerImpl();
    AudioService.init(
        builder: () => audioPlayerHandler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.myapp.audio',
          androidNotificationChannelName: 'Audio Service Demo',
          // androidNotificationOngoing: false,
          androidStopForegroundOnPause: false
        ),
    );

    

    audioPlayerHandler.setCurrentIndexChangedCallback((currentIndex) {


      if(currentIndex!=null) {
        currentMediaItem.value =itemCollection[currentIndex];
        // audioPlayerHandler.queueState.first.then((value) {
        //
        //   try {
        //     currentMediaItem.value = value.queue[currentIndex];
        //
        //
        //
        //   } catch (e) {
        //     // ignoring exceptions
        //   }
        //
        // });

      }else{
        currentMediaItem.value = const MediaItem(id: 'temp', title: 'Playing Nothing');
      }
    });

    audioPlayerHandler.setCurrentPlayingChangedCallback((playing) {

      if(playing!=null) {
        isPlaying.value = playing;
      }else{
        isPlaying.value = false;
      }
    });
  }


  void clearQueue(){
    try {


    }catch (e) {
      customDebugPrint("clear queue catch error : $e");
    }
  }

  Future<void> extractPlaylist(String playlistId) async {


    for(var i=0;i<=audioPlayerHandler.queue.value.length;i++){
      audioPlayerHandler.removeQueueItemAt(i);
    }


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

  void setShuffleMode(){
    if(shuffleActive.value){
      audioPlayerHandler.setShuffleMode(AudioServiceShuffleMode.all);
    }else{
      audioPlayerHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  void setLoopingMode() {
    switch (loopMode.value) {
      case LoopMode.off:
        audioPlayerHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case LoopMode.on:
        audioPlayerHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case LoopMode.single:
        audioPlayerHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
    }
  }


  Future<MediaItem> getMediaItem(String title)async{

    try {
      final video = videoMap[title]!;
      var manifest = await yt.videos.streams.getManifest(video.id.value,requireWatchPage: false);
      var audio = manifest.audioOnly.withHighestBitrate();

      return MediaItem(
        id: audio.url.toString(),
        title: title,
        duration: video.duration,
      );
    } on Exception catch (_) {
      customDebugPrint('getMediaItem error: $_');
      return const MediaItem(id: "", title: "error",duration: Duration(seconds: 0));
    }


  }


  @override
  void dispose() {
    audioPlayerHandler.stop();
    yt.close();
    super.dispose();
  }

  Future<void> buildItemCollection() async {

    isBuildingCollection.value = true;
    itemCollection.clear();
    for (var _ in videoMap.keys) {
      itemCollection.add(const MediaItem(id: 'temp', title: 'Loading...'));
    }

    var keyIndexMap = <String, int>{};
    var i = 0;
    for (var key in videoMap.keys) {
      keyIndexMap[key] = i;
      i++;
    }


    final pool = Pool(40);
    final futures = <Future>[];

    for (var key in videoMap.keys) {
      final f = pool.withResource(() async {
        final item = await getMediaItem(videoMap[key]!.title);
        final index = keyIndexMap[key]!;
        itemCollection[index] = item;
        parseVideoProgress.value++;
      });
      futures.add(f);

    }


    // var futures = videoMap.keys.map((key) async {
    //
    //   final item = await getMediaItem(videoMap[key]!.title);
    //   int index = keyIndexMap[key]!;
    //   itemCollection[index] = item;
    //   parseVideoProgress.value++;
    // }).toList();

    await Future.wait(futures);
    await audioPlayerHandler.updateQueue(itemCollection);
    await pool.close();



    parseVideoProgress.value = 0;
    isBuildingCollection.value = false;

  }


  Future<void> playFromIndex(int index) async {




    if(itemCollection.isEmpty||itemCollection[index].id=="temp"){
      return;
    }



    if(audioPlayerHandler.playbackState.value.playing){
      await audioPlayerHandler.stop();
    }




    // // var reorderedCollection = [...itemCollection.sublist(index), ...itemCollection.sublist(0, index)];
    // await audioPlayerHandler.updateQueue(reorderedCollection);
    // await audioPlayerHandler.seekToIndex(Duration.zero, 0);
    // currentMediaItem.value = reorderedCollection[0];

    await audioPlayerHandler.updateQueue(itemCollection);
    await audioPlayerHandler.seekToIndex(Duration.zero, index);

    currentMediaItem.value = itemCollection[index];
    audioPlayerHandler.play();


  }


  void skipToPrevious() => audioPlayerHandler.skipToPrevious();

  void skipToNext() => audioPlayerHandler.skipToNext();

  pause() => audioPlayerHandler.pause();

  play() => audioPlayerHandler.play();
}

