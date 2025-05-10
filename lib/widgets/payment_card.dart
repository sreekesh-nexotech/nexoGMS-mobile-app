import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(payment.transactionDate);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          // Show modal if needed
        },
        title: Text(
          '₹${payment.amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${payment.paymentMethod ?? 'Method Unknown'} • $formattedDate',
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}
