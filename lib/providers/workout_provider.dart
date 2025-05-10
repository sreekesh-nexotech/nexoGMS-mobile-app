import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_model.dart';
import '../../repositories/workout_repository.dart';

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>(
  (ref) => WorkoutNotifier(WorkoutRepository())..loadWorkouts(),
);

class WorkoutState {
  final bool isLoading;
  final String? error;
  final List<WorkoutDay> workouts;
  final String scheduleName;

  WorkoutState({
    required this.isLoading,
    required this.workouts,
    required this.scheduleName,
    this.error,
  });

  WorkoutState copyWith({
    bool? isLoading,
    List<WorkoutDay>? workouts,
    String? scheduleName,
    String? error,
  }) {
    return WorkoutState(
      isLoading: isLoading ?? this.isLoading,
      workouts: workouts ?? this.workouts,
      scheduleName: scheduleName ?? this.scheduleName,
      error: error,
    );
  }

  factory WorkoutState.initial() => WorkoutState(
        isLoading: true,
        workouts: [],
        scheduleName: 'Workout Schedule',
        error: null,
      );
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutRepository _repo;

  WorkoutNotifier(this._repo) : super(WorkoutState.initial());

 Future<void> loadWorkouts() async {
  try {
    state = state.copyWith(isLoading: true);

    final cached = await _repo.getCachedWorkouts();
    final scheduleName = await _repo.getCachedScheduleName();

    if (cached.isEmpty) {
      // First time: fetch full data
      await _repo.fetchFullWorkouts();
      final workouts = await _repo.getCachedWorkouts();
      final name = await _repo.getCachedScheduleName();
      state = state.copyWith(workouts: workouts, scheduleName: name, isLoading: false);
    } else {
      // If cache exists, try delta update
      state = state.copyWith(workouts: cached, scheduleName: scheduleName);
      await _repo.fetchDeltaUpdates();
      final refreshed = await _repo.getCachedWorkouts();
      state = state.copyWith(workouts: refreshed, isLoading: false);
    }
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}


  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repo.fetchFullWorkouts();
      final refreshed = await _repo.getCachedWorkouts();
      final name = await _repo.getCachedScheduleName();
      state = state.copyWith(workouts: refreshed, scheduleName: name, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
