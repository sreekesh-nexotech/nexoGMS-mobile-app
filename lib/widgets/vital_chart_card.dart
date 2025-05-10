import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/vital_state.dart';

class VitalChartCard extends StatefulWidget {
  final VitalState state;

  const VitalChartCard({super.key, required this.state});

  @override
  State<VitalChartCard> createState() => _VitalChartCardState();
}

class _VitalChartCardState extends State<VitalChartCard> {
  double? bmi;
  String? bmiStatus;
  Color bmiColor = Colors.grey;
  double trend = 0;

  @override
  void initState() {
    super.initState();
    _calculateBMI();
    _calculateTrend();
  }

  Future<void> _calculateBMI() async {
    final box = await Hive.openBox('vitalsData');
    final height = box.get('userHeight');

    double? heightCm;
    if (height is double) heightCm = height;
    if (height is String) heightCm = double.tryParse(height);
    if (height is int) heightCm = height.toDouble();

    if (heightCm != null && heightCm > 0 && widget.state.weights.isNotEmpty) {
      final weight = widget.state.weights.last.weight;
      final heightM = heightCm / 100;
      final calculatedBmi = weight / (heightM * heightM);

      setState(() {
        bmi = calculatedBmi;
        bmiStatus = _getBMIStatus(calculatedBmi);
        bmiColor = _getBMIColor(calculatedBmi);
      });
    }
  }

  void _calculateTrend() {
    final data = widget.state.weights;
    if (data.length >= 2) {
      setState(() {
        trend = data.last.weight - data[data.length - 2].weight;
      });
    }
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 23) return 'Normal';
    if (bmi < 25) return 'Overweight (Asia)';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 23) return Colors.green;
    if (bmi < 25) return Colors.orange;
    return Colors.red;
  }

  IconData _getTrendIcon(double change) {
    return change > 0
        ? Icons.trending_up
        : change < 0
            ? Icons.trending_down
            : Icons.trending_flat;
  }

  String _getTrendText(double change) {
    if (widget.state.weights.length < 2) return 'No change';
    return change > 0 ? '+${change.toStringAsFixed(1)}kg' : '${change.toStringAsFixed(1)}kg';
  }

  Color _getTrendColor(double change) {
    final isPositive = change > 0;
    return isPositive ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3);
  }

  String? getXAxisLabel(int index, String period, List<String> shownLabels, DateTime date) {
    String label;
    switch (period) {
      case 'weekly':
        label = DateFormat('d MMM').format(date);
        return label;
      case 'monthly':
        label = DateFormat('MMM').format(date);
        break;
      case 'all':
      default:
        label = DateFormat('MMM yyyy').format(date);
        break;
    }

    if (shownLabels.contains(label)) return null;
    shownLabels.add(label);
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final weightData = widget.state.weights;
    if (weightData.isEmpty) {
      return Card(
        color: const Color(0xFF0B1739),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No data', style: TextStyle(color: Colors.white54))),
        ),
      );
    }

    final minY = weightData.map((e) => e.weight).reduce(min) - 2;
    final maxY = weightData.map((e) => e.weight).reduce(max) + 2;
    //final shownLabels = <String>[];

    return Card(
      color: const Color(0xFF0B1739),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weight Progress',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${weightData.last.weight.toStringAsFixed(1)} kg ',
                          style: const TextStyle(color: Color(0xFF0064F4), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTrendColor(trend),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(_getTrendIcon(trend), size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(_getTrendText(trend), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(color: bmiColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BMI: ${bmi?.toStringAsFixed(1) ?? "--"} (${bmiStatus ?? "N/A"})',
                        style: TextStyle(color: bmiColor, fontSize: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, _) {
  final index = value.toInt();
  if (index >= 0 && index < weightData.length) {
    final date = DateTime.parse(weightData[index].date);

    // Show every 3rd label to avoid duplicates and improve visibility
    if (index % 3 != 0) return const SizedBox.shrink();

    String label;
    switch (widget.state.selectedPeriod) {
      case 'weekly':
        label = DateFormat('d MMM').format(date);
        break;
      case 'monthly':
        label = DateFormat('MMM').format(date);
        break;
      case 'all':
        label = DateFormat('MMM yyyy').format(date);
        break;
      default:
        label = DateFormat('d MMM').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    );
  }
  return const SizedBox.shrink();
}

                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${value.toInt()} kg',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF57C3FF),
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF57C3FF).withOpacity(0.3),
                            const Color(0xFF0064F4).withOpacity(0.1),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
