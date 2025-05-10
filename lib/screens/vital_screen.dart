import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vital_provider.dart';
//import '../../models/vital_state.dart';
//import '../../models/weight_data.dart';
import '../../widgets/vital_chart_card.dart';
import '../../widgets/vital_input_card.dart';
import '../../widgets/health_record_card.dart';

class VitalScreen extends ConsumerWidget {
  const VitalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vitalProvider);
    final controller = ref.read(vitalProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Health Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0064F4)))
          : RefreshIndicator(
              onRefresh: controller.refreshVitals,
              color: const Color(0xFF0064F4),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPeriodSelector(controller, state.selectedPeriod),
                    const SizedBox(height: 10),
                    if (state.error != null)
                      _buildErrorMessage(state.error!),
                    VitalChartCard(state: state),
                    const SizedBox(height: 24),
                    VitalInputCard(
                      isLoading: state.isUpdating,
                      controller: controller,
                    ),
                    const SizedBox(height: 24),
                    HealthRecordCard(vitals: state.vitals),

                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(controller, String selectedPeriod) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['weekly', 'monthly', 'all'].map((period) {
        final isSelected = selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              period[0].toUpperCase() + period.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF0064F4),
            backgroundColor: const Color.fromARGB(255, 6, 17, 70),
            onSelected: (_) => controller.changePeriod(period),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[200]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[200]),
            ),
          ),
        ],
      ),
    );
  }
}
