class PaymentModel {
  final int paymentId;
  final double amount;
  final String status;
  final String transactionDate;
  final String paymentMethod;
  final String description;

  PaymentModel({
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.transactionDate,
    required this.paymentMethod,
    required this.description,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        paymentId: json['payment_id'],
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] ?? 'pending',
        transactionDate: json['transaction_date'] ?? '',
        paymentMethod: json['payment_method'] ?? 'N/A',
        description: json['description'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'payment_id': paymentId,
        'amount': amount,
        'status': status,
        'transaction_date': transactionDate,
        'payment_method': paymentMethod,
        'description': description,
      };
}
