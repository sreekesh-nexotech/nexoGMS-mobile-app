import 'package:equatable/equatable.dart';
import 'workout_model.dart'; // assuming WorkoutDay and Exercise are here

class HomeState extends Equatable {
  final bool isLoading;
  final int gymStreak;
  final DateTime? feeDueDate;
  final String membershipPlanName;
  final String membershipPlanPeriod;
  final String membershipPlanAmount;
  final bool isMembershipActive;

  final bool isLoadingWorkout;
  final WorkoutDay? todaysWorkout;
  
  final int totalGymDays;
  final bool isLoadingTotalDays;

  final double currentWeight;
  final double targetWeight;
  final bool isLoadingWeight;

  const HomeState({
    required this.isLoading,
    required this.gymStreak,
    required this.feeDueDate,
    required this.membershipPlanName,
    required this.membershipPlanPeriod,
    required this.membershipPlanAmount,
    required this.isMembershipActive,
    required this.isLoadingWorkout,
    required this.todaysWorkout,
    required this.totalGymDays,
    required this.isLoadingTotalDays,
    required this.currentWeight,
    required this.targetWeight,
    required this.isLoadingWeight,
  });

  factory HomeState.initial() => const HomeState(
    isLoading: true,
    gymStreak: 0,
    feeDueDate: null,
    membershipPlanName: '',
    membershipPlanPeriod: '',
    membershipPlanAmount: '',
    isMembershipActive: false,
    isLoadingWorkout: true,
    todaysWorkout: null,
    totalGymDays: 0,
    isLoadingTotalDays: true,
    currentWeight: 0.0,
    targetWeight: 0.0,
    isLoadingWeight: true,
  );

  HomeState copyWith({
    bool? isLoading,
    int? gymStreak,
    DateTime? feeDueDate,
    String? membershipPlanName,
    String? membershipPlanPeriod,
    String? membershipPlanAmount,
    bool? isMembershipActive,
    bool? isLoadingWorkout,
    WorkoutDay? todaysWorkout,
    int? totalGymDays,
    bool? isLoadingTotalDays,
    double? currentWeight,
    double? targetWeight,
    bool? isLoadingWeight,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      gymStreak: gymStreak ?? this.gymStreak,
      feeDueDate: feeDueDate ?? this.feeDueDate,
      membershipPlanName: membershipPlanName ?? this.membershipPlanName,
      membershipPlanPeriod: membershipPlanPeriod ?? this.membershipPlanPeriod,
      membershipPlanAmount: membershipPlanAmount ?? this.membershipPlanAmount,
      isMembershipActive: isMembershipActive ?? this.isMembershipActive,
      isLoadingWorkout: isLoadingWorkout ?? this.isLoadingWorkout,
      todaysWorkout: todaysWorkout ?? this.todaysWorkout,
      totalGymDays: totalGymDays ?? this.totalGymDays,
      isLoadingTotalDays: isLoadingTotalDays ?? this.isLoadingTotalDays,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      isLoadingWeight: isLoadingWeight ?? this.isLoadingWeight,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    gymStreak,
    feeDueDate,
    membershipPlanName,
    membershipPlanPeriod,
    membershipPlanAmount,
    isMembershipActive,
    isLoadingWorkout,
    todaysWorkout,
    totalGymDays,
    isLoadingTotalDays,
    currentWeight,
    targetWeight,
    isLoadingWeight,
  ];
}
