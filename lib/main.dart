import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yt_bg_player/home/view.dart';

import 'home/logic.dart';

void main() {
  final logic = Get.put(HomeLogic());
  logic.initPlayer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      theme: ThemeData.dark(), // 设置为暗色主题
      home: HomePage(),
    );
  }
}


void customDebugPrint(dynamic input) {
  if (kDebugMode) {
    final now = DateTime.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    print('[$formattedTime] $input');
  }
}