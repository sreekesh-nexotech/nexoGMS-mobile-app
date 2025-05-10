import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/home_state.dart';
import '../../repositories/home_repository.dart';
import '../../services/cache_utils.dart';
import '../../models/workout_model.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(HomeRepository())..initialize(),
);

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repo;

  HomeNotifier(this._repo) : super(HomeState.initial());

  Future<void> initialize() async {
    await _loadCachedData();
    await _fetchFreshData(); // don't await this if you want non-blocking background load
  }

  Future<void> _loadCachedData() async {
    final cached = await _repo.getCachedHomeData();
    if (cached != null) {
      state = state.copyWith(
        gymStreak: cached.gymStreak,
        feeDueDate: cached.feeDueDate,
        membershipPlanName: cached.membershipPlanName,
        membershipPlanPeriod: cached.membershipPlanPeriod,
        membershipPlanAmount: cached.membershipPlanAmount,
        isMembershipActive: cached.isMembershipActive,
        todaysWorkout: cached.todaysWorkout,
        totalGymDays: cached.totalGymDays,
        currentWeight: cached.currentWeight,
        targetWeight: cached.targetWeight,
        isLoading: false,
        isLoadingWorkout: false,
        isLoadingTotalDays: false,
        isLoadingWeight: false,
      );
    }
  }

  Future<void> _fetchFreshData() async {
    try {
      final results = await Future.wait([
        _repo.fetchHomeData(),
        _repo.fetchTodaysWorkout(),
        _repo.fetchTotalGymDays(),
        _repo.fetchWeights(),
      ]);

      final freshData = results[0] as HomeState;
      final todaysWorkout = results[1] as WorkoutDay?;
      final totalDays = results[2] as int;
      final weights = results[3] as Map<String, double>;

      state = state.copyWith(
        gymStreak: freshData.gymStreak,
        feeDueDate: freshData.feeDueDate,
        membershipPlanName: freshData.membershipPlanName,
        membershipPlanPeriod: freshData.membershipPlanPeriod,
        membershipPlanAmount: freshData.membershipPlanAmount,
        isMembershipActive: freshData.isMembershipActive,
        todaysWorkout: todaysWorkout,
        totalGymDays: totalDays,
        currentWeight: weights['current'],
        targetWeight: weights['target'],
        isLoading: false,
        isLoadingWorkout: false,
        isLoadingTotalDays: false,
        isLoadingWeight: false,
      );

      await _repo.cacheHomeData(state);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingWorkout: false,
        isLoadingTotalDays: false,
        isLoadingWeight: false,
      );
    }
  }

  Future<void> refreshData() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingWorkout: true,
      isLoadingTotalDays: true,
      isLoadingWeight: true,
    );
    await _fetchFreshData();
  }

  Future<void> logout() async {
    await CacheManager.clearAll();
    state = HomeState.initial();
  }
}
