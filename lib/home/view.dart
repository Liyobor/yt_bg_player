import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class HomePage extends StatelessWidget {
  final logic = Get.put(HomeLogic());

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Playlist Player'),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Obx(() => Padding(
              padding: const EdgeInsets.fromLTRB(16,8,16,0),
              child: Text(
                logic.currentMediaItem.value.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    logic.skipToPrevious();
                  },
                ),
                Obx(() => IconButton(
                  icon: Icon(
                      logic.isPlaying.value ? Icons.pause : Icons.play_arrow
                  ),
                  onPressed: () {
                    logic.isPlaying.value ? logic.pause() : logic.play();
                  },
                )),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    logic.skipToNext();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0,16.0,16.0,0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Enter YouTube Playlist ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => logic.videoId.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0,0,16.0,0),
            child: ElevatedButton(
              onPressed: (){
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                debugPrint("Extract btn clicked!");
                logic.extractPlaylist(logic.videoId.value).whenComplete(() => Get.back());
              },
              child: const Text('Extract Playlist Audio'),
            ),
          ),
          // const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0,0,16.0,8.0),
            child: Row(
              children: [
                Row(
                  children: [
                    Obx(() => IconButton(
                      icon: Icon(
                        logic.loopMode.value == LoopMode.single ? Icons.repeat_one_on_outlined :
                        (logic.loopMode.value == LoopMode.on ? Icons.repeat_on : Icons.repeat),
                        color: logic.loopMode.value == LoopMode.off ? Colors.grey : Colors.blue,
                      ),
                      onPressed: () {
                        if (logic.loopMode.value == LoopMode.off) {
                          logic.loopMode.value = LoopMode.on;
                        } else if (logic.loopMode.value == LoopMode.on) {
                          logic.loopMode.value = LoopMode.single;
                        } else {
                          logic.loopMode.value = LoopMode.off;
                        }
                        logic.setLoopingMode();
                      },
                    )),
                    const SizedBox(width: 16),
                    Obx(() => IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: logic.shuffleActive.value ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        logic.shuffleActive.value = !logic.shuffleActive.value;
                        logic.setShuffleMode();
                      },
                    )),
                  ],
                ),
              ],
            ),
          ),
          // const SizedBox(height: 16),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: logic.itemCollection.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(logic.itemCollection[index].title),
                  onTap: () {
                    debugPrint("index = $index");
                    logic.playFromIndex(index);
                    // final title = logic.titles[index];
                    // logic.playAudioByTitle(title);
                  },
                );
              },
            )),
          ),
          Obx(() {
            if (!logic.isBuildingCollection.value) {
              return Container();
            }
            double progressValue = logic.videoMap.isEmpty ? 0 : logic.parseVideoProgress.value / logic.videoMap.length;
            return LinearProgressIndicator(value: progressValue);
          })
        ],
      ),
    );
  }
}