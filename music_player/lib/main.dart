import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'providers/music_provider.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_player.channel.audio',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => MusicProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSongs();
    });
  }

  Future<void> _loadSongs() async {
    debugPrint('Starting song loading process...');
    final musicProvider = context.read<MusicProvider>();
    await musicProvider.initialize();
    await musicProvider.refreshLibrary();
    debugPrint('Songs loaded: ${musicProvider.allSongs.length}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const AppShell(),
    );
  }
}
