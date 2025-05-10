import 'package:flutter/foundation.dart';
import 'workout_model.dart';

@immutable
class WorkoutState {
  final List<WorkoutDay> workouts;
  final bool isLoading;
  final String error;
  final String scheduleName;

  const WorkoutState({
    required this.workouts,
    required this.isLoading,
    required this.error,
    required this.scheduleName,
  });

  factory WorkoutState.initial() {
    return const WorkoutState(
      workouts: [],
      isLoading: true,
      error: '',
      scheduleName: 'Workout Schedule',
    );
  }

  WorkoutState copyWith({
    List<WorkoutDay>? workouts,
    bool? isLoading,
    String? error,
    String? scheduleName,
  }) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      scheduleName: scheduleName ?? this.scheduleName,
    );
  }
}
