import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/workout_model.dart';
import '../services/api_service.dart';

class WorkoutRepository {
  final ApiService _api = ApiService();
  final String _boxName = 'workoutData';
  final String _keyWorkouts = 'workouts';
  final String _keyScheduleName = 'scheduleName';
  final String _keyLastSync = 'lastSync';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<List<WorkoutDay>> getCachedWorkouts() async {
  final box = await _openBox();
  final raw = box.get(_keyWorkouts) ?? [];
  return (raw as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .map(WorkoutDay.fromJson)
      .toList();
}


  Future<String> getCachedScheduleName() async {
    final box = await _openBox();
    return box.get(_keyScheduleName, defaultValue: 'Workout Schedule');
  }

  Future<void> fetchFullWorkouts() async {
    final response = await _api.authenticatedGet('workout/workouts');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final workouts = data['workouts'] as List;
      final box = await _openBox();
      await box.put(_keyWorkouts, workouts);
      await box.put(_keyScheduleName, data['name'] ?? 'Workout Schedule');
      await box.put(_keyLastSync, DateTime.now().toUtc().toIso8601String());
    } else {
      throw Exception('Failed to fetch workouts');
    }
  }

  Future<void> fetchDeltaUpdates() async {
    final box = await _openBox();
    final lastSync = box.get(_keyLastSync);
    final response = await _api.authenticatedGet(
      'workout/workouts-delta',
      queryParameters: {'since': lastSync},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final cached = await getCachedWorkouts();
      final updates = (data['workouts'] as List)
          .map((e) => WorkoutDay.fromJson(e))
          .toList();

      final merged = {
        for (var w in cached) w.id: w,
        for (var u in updates) u.id: u,
      }.values.toList();

      await box.put(_keyWorkouts, merged.map((e) => {
            'exercise_group_id': e.id,
            'name': e.name,
            'exercises': e.exercises.map((x) => {
                  'name': x.name,
                  'set_count': x.setCount,
                  'rep_count': x.repCount,
                  'description': x.description,
                  'video_mapping': x.videoUrl,
                }).toList(),
          }).toList());
      await box.put(_keyLastSync, DateTime.now().toUtc().toIso8601String());
    }
  }
}
