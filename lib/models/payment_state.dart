import 'payment_model.dart';

class PaymentState {
  final List<PaymentModel> payments;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasError;
  final String? errorMessage;
  final DateTime? lastUpdated;

  PaymentState({
    required this.payments,
    required this.isLoading,
    required this.isRefreshing,
    required this.hasError,
    this.errorMessage,
    this.lastUpdated,
  });

  factory PaymentState.initial() => PaymentState(
        payments: [],
        isLoading: true,
        isRefreshing: false,
        hasError: false,
        errorMessage: null,
        lastUpdated: null,
      );

  PaymentState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasError,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

