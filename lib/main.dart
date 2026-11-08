import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'theme.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.personal.music_player.audio',
    androidNotificationChannelName: 'Music+ playback',
    androidNotificationOngoing: true,
  );
  runApp(const MusicPlusApp());
}

class MusicPlusApp extends StatelessWidget {
  const MusicPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music+',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const RootShell(),
    );
  }
}
