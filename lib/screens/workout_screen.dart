import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../screens/exercise_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutProvider);
    final controller = ref.read(workoutProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        title: Text(state.scheduleName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        // ✅ Removed refresh icon
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0064F4)))
          : state.error != null
              ? Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
              : _buildWorkoutList(state, context, controller),
    );
  }

  Widget _buildWorkoutList(WorkoutState state, BuildContext context, WorkoutNotifier controller) {
    if (state.workouts.isEmpty) {
      return const Center(
        child: Text('No workouts scheduled', style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      color:  Colors.white,
      backgroundColor: const Color(0xFF0B1739),
      onRefresh: () => controller.refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Workout Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.workouts.length} days this week',
              style: const TextStyle(
                color: Color(0xFFAEB9E1),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.workouts.length,
                itemBuilder: (context, index) {
                  final w = state.workouts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      tileColor: const Color(0xFF0B1739),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(w.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${w.exercises.length} ${w.exercises.length == 1 ? "exercise" : "exercises"}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseScreen(
                              day: 'Day ${index + 1}',
                              bodyPart: w.name,
                              exercises: w.exercises,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
