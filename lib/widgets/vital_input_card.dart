import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import '../providers/vital_provider.dart';

class VitalInputCard extends StatefulWidget {
  final bool isLoading;
  final VitalNotifier controller;

  const VitalInputCard({super.key, required this.isLoading, required this.controller});

  @override
  State<VitalInputCard> createState() => _VitalInputCardState();
}

class _VitalInputCardState extends State<VitalInputCard> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B1739),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record New Weight',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 15, 27, 85),
                  prefixIcon: const Icon(Icons.monitor_weight, color: Color.fromARGB(255, 217, 221, 226)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final weight = double.tryParse(value ?? '');
                  if (weight == null || weight <= 0 || weight > 300) {
                    return 'Enter a valid weight (0-300 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            widget.controller.addWeight(double.parse(_controller.text));
                            _controller.clear();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064F4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('SAVE WEIGHT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
