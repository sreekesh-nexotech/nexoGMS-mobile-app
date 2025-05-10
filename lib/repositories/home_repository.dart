import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/home_state.dart';
import '../models/workout_model.dart';
import '../services/api_service.dart';

class HomeRepository {
  final _apiService = ApiService();
  final _boxName = 'home_cache';

  Future<Box> _getCacheBox() async => await Hive.openBox(_boxName);

  Future<HomeState?> getCachedHomeData() async {
    final box = await _getCacheBox();
    if (box.isEmpty) return null;

    try {
      final membershipPlan = jsonDecode(box.get('membership_plan') ?? '{}');
      final workoutRaw = box.get('todays_workout');
      WorkoutDay? todaysWorkout;
      if (workoutRaw != null) {
        todaysWorkout = WorkoutDay.fromJson(jsonDecode(workoutRaw));
      }

      return HomeState(
        gymStreak: box.get('gym_streak') ?? 0,
        feeDueDate: DateTime.tryParse(box.get('fee_due_date') ?? ''),
        membershipPlanName: membershipPlan['plan_name'] ?? '',
        membershipPlanPeriod: '${membershipPlan['period']} months',
        membershipPlanAmount: '₹${membershipPlan['amount']}',
        isMembershipActive: membershipPlan['is_active'] ?? false,
        todaysWorkout: todaysWorkout,
        totalGymDays: box.get('total_gym_days') ?? 0,
        currentWeight: box.get('current_weight') ?? 0.0,
        targetWeight: box.get('target_weight') ?? 0.0,
        isLoading: false,
        isLoadingWorkout: false,
        isLoadingTotalDays: false,
        isLoadingWeight: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheHomeData(HomeState state) async {
    final box = await _getCacheBox();

    await box.put('gym_streak', state.gymStreak);
    await box.put('fee_due_date', state.feeDueDate?.toIso8601String());
    await box.put(
        'membership_plan',
        jsonEncode({
          'plan_name': state.membershipPlanName,
          'period': state.membershipPlanPeriod.replaceAll(' months', ''),
          'amount': state.membershipPlanAmount.replaceAll('₹', ''),
          'is_active': state.isMembershipActive,
        }));
    await box.put('total_gym_days', state.totalGymDays);
    await box.put('current_weight', state.currentWeight);
    await box.put('target_weight', state.targetWeight);

    if (state.todaysWorkout != null) {
      await box.put('todays_workout', jsonEncode(state.todaysWorkout!.toJson()));
    }
  }

  Future<HomeState> fetchHomeData() async {
    final gymStreak = await _fetchGymStreak();
    final feeDueDate = await _fetchFeeDueDate();
    final membership = await _fetchMembershipPlan();

    return HomeState(
      gymStreak: gymStreak,
      feeDueDate: feeDueDate,
      membershipPlanName: membership['plan_name'] ?? '',
      membershipPlanPeriod: '${membership['period']} months',
      membershipPlanAmount: '₹${membership['amount']}',
      isMembershipActive: membership['is_active'] ?? false,
      isLoading: false,
      isLoadingWorkout: true,
      todaysWorkout: null,
      totalGymDays: 0,
      isLoadingTotalDays: true,
      currentWeight: 0.0,
      targetWeight: 0.0,
      isLoadingWeight: true,
    );
  }

  Future<WorkoutDay?> fetchTodaysWorkout() async {
    final res = await _apiService.authenticatedGet('workout/workouts');
    final data = jsonDecode(res.body);
    final workouts = (data['workouts'] as List)
        .map((e) => WorkoutDay.fromJson(e))
        .toList();
    if (workouts.isEmpty) return null;
    final index = DateTime.now().weekday % workouts.length;
    return workouts[index];
  }

  Future<int> fetchTotalGymDays() async {
    final res = await _apiService.authenticatedGet('workout/total-gym-days');
    final data = jsonDecode(res.body);
    return data['total_days'] ?? 0;
  }

  Future<Map<String, double>> fetchWeights() async {
    final currentRes = await _apiService.authenticatedGet('vital/vitals/current-weight');
    final targetRes = await _apiService.authenticatedGet('customer/target-weight');
    final current = jsonDecode(currentRes.body)['weight'] ?? 0.0;
    final target = jsonDecode(targetRes.body)['target_weight'] ?? 0.0;
    return {
      'current': current.toDouble(),
      'target': target.toDouble(),
    };
  }

  Future<int> _fetchGymStreak() async {
    final res = await _apiService.authenticatedGet('workout/gym-streak');
    final data = jsonDecode(res.body);
    return data['streak'] ?? 0;
  }

  Future<DateTime?> _fetchFeeDueDate() async {
    final res = await _apiService.authenticatedGet('customer/fee-due-date');
    final data = jsonDecode(res.body);
    return data['fee_due_date'] != null ? DateTime.parse(data['fee_due_date']) : null;
  }

  Future<Map<String, dynamic>> _fetchMembershipPlan() async {
    final res = await _apiService.authenticatedGet('customer/customer/flutter/membership-plan');
    return jsonDecode(res.body);
  }
}
