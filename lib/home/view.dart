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
                  barrierDismissible: false, // 使其不能被點擊外部區域來關閉
                );
                debugPrint("Extract btn clicked!");
                logic.extractPlaylist(logic.videoId.value).whenComplete(() => Get.back());
              },
              child: const Text('Extract Playlist Audio'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: logic.titles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(logic.titles[index]),
                    onTap: () {

                      final titles = logic.titles[index];
                      final id = logic.videoIdMap[titles]!;
                      logic.getAudioFromVideoId(id).then((value) => logic.playAudio(value.toString()));
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}