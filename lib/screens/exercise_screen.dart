import 'package:flutter/material.dart';
import '../../models/workout_model.dart';
import '../../widgets/exercise_video_player.dart';
import 'exercise_video_player_screen.dart';

class ExerciseScreen extends StatelessWidget {
  final String day;
  final String bodyPart;
  final List<Exercise> exercises;

  const ExerciseScreen({
    required this.day,
    required this.bodyPart,
    required this.exercises,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        title: Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF081028),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: exercises.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildExerciseCard(context, exercises[index], index),
            ),
    );
  }

  Widget _buildEmptyState() => const Center(
        child: Text('No exercises today', style: TextStyle(color: Colors.white)),
      );

  Widget _buildExerciseCard(BuildContext context, Exercise exercise, int index) {
    final accentColors = [Colors.blueAccent];
    final accent = accentColors[index % accentColors.length];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color:  const Color.fromARGB(255, 2, 75, 109),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(Icons.fitness_center, color: Colors.grey, size: 60)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (exercise.repCount != null)
                  Text('${exercise.repCount} reps', style: TextStyle(color: Colors.grey[400])),
                if (exercise.description != null && exercise.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(exercise.description!, style: TextStyle(color: Colors.grey[400])),
                  ),
                if (exercise.videoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseVideoPlayerScreen(
        videoUrl: exercise.videoUrl!,
        accentColor: accent,
      ),
      fullscreenDialog: true,
    ),
  );
},

                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('View Exercise Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String videoUrl, Color accent) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 250, child: ExerciseVideoPlayer(videoUrl: videoUrl)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
