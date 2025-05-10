import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ExerciseVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

 void _initializeVideo() {
  if (widget.videoUrl.contains('youtube.com') || widget.videoUrl.contains('youtu.be')) {
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  } else {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
        );
        setState(() {});
      });
  }
}


  @override
  void dispose() {
    _youtubeController?.close();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   if (_youtubeController != null) {
  return YoutubePlayerScaffold(
    controller: _youtubeController!,
    builder: (context, player) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: player,
      );
    },
  );
} else if (_chewieController != null) {
  return Chewie(controller: _chewieController!);
} else {
  return const Center(child: CircularProgressIndicator());

}
  }
}