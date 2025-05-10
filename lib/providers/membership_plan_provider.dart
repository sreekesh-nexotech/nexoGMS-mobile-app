import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/membership_plan_state.dart';
import '../../repositories/membership_plan_repository.dart';

final membershipPlanProvider = StateNotifierProvider<MembershipPlanNotifier, MembershipPlanState>(
  (ref) => MembershipPlanNotifier(MembershipPlanRepository())..loadPlans(),
);

class MembershipPlanNotifier extends StateNotifier<MembershipPlanState> {
  final MembershipPlanRepository _repo;

  MembershipPlanNotifier(this._repo) : super(MembershipPlanState.initial());

  Future<void> loadPlans() async {
    try {
      state = state.copyWith(isLoading: true);
      final cached = await _repo.getCachedPlans();
      if (cached.isNotEmpty) {
        state = state.copyWith(plans: cached, isLoading: false);
      }

      final fresh = await _repo.fetchPlans();
      state = state.copyWith(plans: fresh, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshPlans() async {
    await _repo.clearCache();
    await loadPlans();
  }
}
