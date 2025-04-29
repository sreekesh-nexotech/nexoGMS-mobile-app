import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'exercise_screen.dart';
import 'api_service.dart';
//import 'login_screen.dart';
import '../services/hive_service.dart'; //Added by sreekesh

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<dynamic> workoutDays = [];
  bool isLoading = true;
  String errorMessage = '';
  String scheduleName = 'Workout Schedule';
  final ApiService _apiService = ApiService();

  // Hive configuration
  static const String _workoutBoxName = 'workoutData';
  static const String _workoutsKey = 'workouts';
  static const String _lastSyncKey = 'lastSync';
  static const String _scheduleNameKey = 'scheduleName';

  Box? _workoutBox;

  @override
  void initState() {
    super.initState();
    _initCacheAndLoadData();
  }

  // CHANGED: Renamed and simplified initialization
  Future<void> _initCacheAndLoadData() async {
    try {
      _workoutBox = await HiveService.openBox(_workoutBoxName);
      _loadCachedDataOrFetch();
    } catch (e) {
      _fetchFullWorkoutData(); // Fallback if Hive fails
    }
  }

  // NEW: Simplified loading logic
  Future<void> _loadCachedDataOrFetch() async {
    final box = _workoutBox!;
    final hasCache =
        box.get(_workoutsKey) != null && box.get(_lastSyncKey) != null;

    setState(() => isLoading = true);

    if (!hasCache) {
      await _fetchFullWorkoutData();
    } else {
      await _checkForUpdates();
    }
  }

  // CHANGED: Simplified update check
  Future<void> _checkForUpdates() async {
    try {
      final lastSync = _workoutBox!.get(_lastSyncKey);
      final response = await _apiService.authenticatedGet(
        'workout/check-exercise-updates',
        queryParameters: {'since': lastSync.toIso8601String()},
      );

      final updateData = json.decode(response.body);

      if (updateData['hasUpdates'] == true) {
        await _fetchDeltaUpdates();
      } else {
        _loadFromCache();
      }
    } catch (e) {
      _loadFromCache(); // Fallback to cache if update check fails
    }
  }

  // CHANGED: Renamed and simplified full fetch
  Future<void> _fetchFullWorkoutData() async {
    try {
      final response = await _apiService.authenticatedGet('workout/workouts');
      final data = json.decode(response.body);

      await _workoutBox!.putAll({
        _workoutsKey: data['workouts'] ?? [],
        _scheduleNameKey: data['name'] ?? 'Workout Schedule',
        _lastSyncKey: DateTime.now().toUtc(),
      });

      _updateUIFromCache();
    } catch (e) {
      setState(() => errorMessage = 'Failed to load workouts');
      _loadFromCache(); // Try showing cached data even if fresh fetch fails
    } finally {
      setState(() => isLoading = false);
    }
  }

  // NEW: Dedicated delta update method
  Future<void> _fetchDeltaUpdates() async {
    try {
      final lastSync = _workoutBox!.get(_lastSyncKey);
      final response = await _apiService.authenticatedGet(
        'workout/workouts-delta',
        queryParameters: {'since': lastSync.toIso8601String()},
      );

      final data = json.decode(response.body);
      final box = _workoutBox!;

      // Merge delta updates
      final cachedWorkouts = box.get(_workoutsKey);
      final updatedWorkouts = _mergeWorkouts(cachedWorkouts, data['workouts']);

      await box.putAll({
        _workoutsKey: updatedWorkouts,
        _lastSyncKey: DateTime.now().toUtc(),
      });

      _updateUIFromCache();
    } catch (e) {
      _loadFromCache(); // Fallback to full cache if delta fails
    } finally {
      setState(() => isLoading = false);
    }
  }

  // CHANGED: Simplified cache loading
  void _loadFromCache() {
    final box = _workoutBox!;
    if (box.get(_workoutsKey) != null) {
      _updateUIFromCache();
    } else {
      _fetchFullWorkoutData(); // If cache is empty, force full refresh
    }
    setState(() => isLoading = false);
  }

  // NEW: Unified UI update from cache
  void _updateUIFromCache() {
    final box = _workoutBox!;
    setState(() {
      scheduleName = box.get(
        _scheduleNameKey,
        defaultValue: 'Workout Schedule',
      );
      workoutDays = box.get(_workoutsKey, defaultValue: []);
      errorMessage = '';
    });
  }

  // CHANGED: Simplified merge logic
  List<dynamic> _mergeWorkouts(List<dynamic> cached, List<dynamic> updates) {
    final workoutMap = {for (var w in cached) w['exercise_group_id']: w};
    for (var update in updates) {
      workoutMap[update['exercise_group_id']] = update;
    }
    return workoutMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF081028),
      appBar: AppBar(
        title: Text(
          scheduleName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF081028),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFAEB9E1)),
            onPressed: () => _fetchFullWorkoutData(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0064F4), strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading your plan...',
              style: TextStyle(color: Color(0xFFAEB9E1), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B1739).withOpacity(0.6),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red[300],
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(color: Color(0xFFAEB9E1), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _fetchFullWorkoutData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0064F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (workoutDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF0B1739).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: Color(0xFFAEB9E1),
                size: 50,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No workouts scheduled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your training plan will appear here once assigned by your coach',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAEB9E1), fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Workout Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${workoutDays.length} days this week',
            style: TextStyle(color: Color(0xFFAEB9E1), fontSize: 14),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: BouncingScrollPhysics(),
              itemCount: workoutDays.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workout = workoutDays[index];
                return _buildWorkoutCard(
                  context,
                  'Day ${index + 1}',
                  workout['name'],
                  workout,
                  index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    String day,
    String bodyPart,
    dynamic workoutData,
    int dayNumber,
  ) {
    final exerciseCount = workoutData['exercises']?.length ?? 0;
    final colors = [Color(0xFF0064F4), Color(0xFF00C4FF), Color(0xFFAEB9E1)];
    final cardColor = colors[dayNumber % colors.length].withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0B1739).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ExerciseScreen(
                      day: '$day - $bodyPart',
                      bodyPart: bodyPart,
                      exercises: workoutData['exercises'],
                    ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors[dayNumber % colors.length].withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: colors[dayNumber % colors.length],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bodyPart,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$day • $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                        style: TextStyle(
                          color: Color(0xFFAEB9E1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: colors[dayNumber % colors.length],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
