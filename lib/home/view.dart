import 'package:audio_service/audio_service.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter YouTube Playlist ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => logic.videoId.value = value,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
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
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: logic.itemCollection.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(logic.itemCollection[index].title),
                    onTap: () {
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
      ),
    );
  }
}