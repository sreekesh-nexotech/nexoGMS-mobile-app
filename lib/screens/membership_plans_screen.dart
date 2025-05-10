import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/membership_plan_provider.dart';
import '../../models/membership_plan_model.dart';
import 'package:intl/intl.dart';

class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(membershipPlanProvider);
    final controller = ref.read(membershipPlanProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        title: const Text('Available Membership Plans', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF081028),
        leading: BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshPlans,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0064F4)))
          : state.error != null
              ? _buildError(state.error!, controller)
              : _buildPlansList(state.plans),
    );
  }

  Widget _buildError(String message, MembershipPlanNotifier controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.refreshPlans,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0064F4)),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<MembershipPlan> plans) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) => _buildPlanCard(plans[index]),
    );
  }

  Widget _buildPlanCard(MembershipPlan plan) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, spreadRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
  child: Text(
    plan.name,
    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0064F4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0064F4), width: 1),
                  ),
                  child: Text('${plan.period} months', style: const TextStyle(color: Color(0xFF0064F4), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(plan.description, style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                Text(currency.format(plan.amount), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
            //  child: ElevatedButton(
             //   onPressed: () {},
              //  style: ElevatedButton.styleFrom(
              //    backgroundColor: const Color(0xFFAEB9E1),
              //    padding: const EdgeInsets.symmetric(vertical: 14),
             //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             //   ),
                //child: const Text('REQUEST ENROLLMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             // ),
            ),
          ],
        ),
      ),
    );
  }
}
