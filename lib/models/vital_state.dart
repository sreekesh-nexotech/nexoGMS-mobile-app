import 'vital_model.dart';

class VitalState {
  final List<WeightData> weights;
  final List<VitalRecord> vitals;
  final bool isLoading;
  final bool isUpdating;
  final String selectedPeriod;
  final String? error;

  VitalState({
    required this.weights,
    required this.vitals,
    required this.isLoading,
    required this.isUpdating,
    required this.selectedPeriod,
    this.error,
  });

  factory VitalState.initial() => VitalState(
        weights: [],
        vitals: [],
        isLoading: true,
        isUpdating: false,
        selectedPeriod: 'weekly',
        error: null,
      );

  VitalState copyWith({
    List<WeightData>? weights,
    List<VitalRecord>? vitals,
    bool? isLoading,
    bool? isUpdating,
    String? selectedPeriod,
    String? error,
  }) {
    return VitalState(
      weights: weights ?? this.weights,
      vitals: vitals ?? this.vitals,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      error: error,
    );
  }
}
