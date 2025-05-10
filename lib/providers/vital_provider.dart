import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vital_state.dart';
import '../../repositories/vital_repository.dart';

final vitalProvider = StateNotifierProvider<VitalNotifier, VitalState>(
  (ref) => VitalNotifier(VitalRepository())..loadInitial(),
);

class VitalNotifier extends StateNotifier<VitalState> {
  final VitalRepository _repo;

  VitalNotifier(this._repo) : super(VitalState.initial());

  Future<void> loadInitial() async {
  try {
    state = state.copyWith(isLoading: true);
    await _repo.ensureHeightCached();

    final cachedWeights = await _repo.getCachedWeights();
    final cachedVitals = await _repo.getCachedVitals();

    if (cachedWeights.isEmpty || cachedVitals.isEmpty) {
      // Fetch from API only if cache is empty
      final freshWeights = await _repo.fetchWeights(state.selectedPeriod);
      final freshVitals = await _repo.fetchVitals();
      state = state.copyWith(
        weights: freshWeights,
        vitals: freshVitals,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        weights: cachedWeights,
        vitals: cachedVitals,
        isLoading: false,
      );
    }
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
  }
}

  Future<void> refreshVitals() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repo.ensureHeightCached(); 
      final weights = await _repo.fetchWeights(state.selectedPeriod);
      final vitals = await _repo.fetchVitals();
      state = state.copyWith(weights: weights, vitals: vitals, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addWeight(double weight) async {
    try {
      state = state.copyWith(isUpdating: true);
      await _repo.saveWeight(weight);
      await refreshVitals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isUpdating: false);
    }
  }

  void changePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
    refreshVitals();
  }
}
