import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment_model.dart';
import '../../repositories/payment_repository.dart';

final paymentProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<List<PaymentModel>>>(
  (ref) => PaymentNotifier(PaymentRepository())..loadPayments(),
);

class PaymentNotifier extends StateNotifier<AsyncValue<List<PaymentModel>>> {
  final PaymentRepository _repo;

  PaymentNotifier(this._repo) : super(const AsyncLoading());

  Future<void> loadPayments() async {
    try {
      final cached = await _repo.getCachedPayments();
      if (cached.isNotEmpty) {
        state = AsyncData(cached);
      }

      final fresh = await _repo.fetchPayments();
      state = AsyncData(fresh);
      await _repo.savePayments(fresh);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refreshPayments() async {
    state = const AsyncLoading();
    await loadPayments();
  }
}
