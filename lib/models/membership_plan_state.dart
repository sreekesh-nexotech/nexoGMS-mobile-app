import 'membership_plan_model.dart';

class MembershipPlanState {
  final List<MembershipPlan> plans;
  final bool isLoading;
  final String? error;

  MembershipPlanState({
    required this.plans,
    required this.isLoading,
    this.error,
  });

  factory MembershipPlanState.initial() => MembershipPlanState(
        plans: [],
        isLoading: true,
        error: null,
      );

  MembershipPlanState copyWith({
    List<MembershipPlan>? plans,
    bool? isLoading,
    String? error,
  }) {
    return MembershipPlanState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
