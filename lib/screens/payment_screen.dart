import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentProvider);
    final controller = ref.read(paymentProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        centerTitle: true,
        title: const Text('Payment History', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshPayments,
          )
        ],
      ),
      body: state.when(
        data: (payments) => payments.isEmpty
            ? const Center(child: Text('No payment records', style: TextStyle(color: Colors.white)))
            : RefreshIndicator(
                onRefresh: controller.refreshPayments,
                color: Colors.blue,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (_, i) => _buildCard(payments[i], context),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blue)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text('$err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: controller.refreshPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PaymentModel p, BuildContext context) {
    final date = DateTime.tryParse(p.transactionDate);
    final dateStr = date != null ? DateFormat('MMM dd, yyyy').format(date) : p.transactionDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text('₹${p.amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.description, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 4),
            Text('$dateStr • ${p.paymentMethod}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        trailing: _buildStatusBadge(p.status),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    Color color;
    String label;

    if (lower == 'completed') {
      color = Colors.green;
      label = 'Paid';
    } else if (lower == 'pending') {
      color = Colors.orange;
      label = 'Pending';
    } else {
      color = Colors.red;
      label = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
