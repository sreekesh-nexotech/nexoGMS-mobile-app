import 'package:flutter/material.dart';
import '../widgets/exercise_video_player.dart';

class ExerciseVideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final Color accentColor;

  const ExerciseVideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Exercise Video', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ExerciseVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }
}
