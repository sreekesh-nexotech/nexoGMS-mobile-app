import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vital_model.dart';
import '../services/api_service.dart';

class HealthRecordCard extends StatefulWidget {
  final List<VitalRecord> vitals;

  const HealthRecordCard({super.key, required this.vitals});

  @override
  State<HealthRecordCard> createState() => _HealthRecordCardState();
}

class _HealthRecordCardState extends State<HealthRecordCard> {
  final Map<String, bool> _expanded = {
    'bloodSugar': false,
    'cholesterol': false,
    'creatinine': false,
    'ldl': false,
  };

  @override
  Widget build(BuildContext context) {
    final latest = _latestPerVital(widget.vitals);
    final history = _historyGrouped(widget.vitals);

    return Card(
      color: const Color(0xFF0B1739),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Health Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    _showUpdateVitalDialog(context);
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalSection(
              label: 'Blood Sugar',
              icon: Icons.bloodtype,
              field: 'bloodSugar',
              unit: 'mg/dL',
              latestValue: latest['bloodSugar'],
              historyList: history['bloodSugar'] ?? [],
            ),
            _buildVitalSection(
              label: 'Cholesterol',
              icon: Icons.favorite,
              field: 'cholesterol',
              unit: 'mg/dL',
              latestValue: latest['cholesterol'],
              historyList: history['cholesterol'] ?? [],
            ),
            _buildVitalSection(
              label: 'Creatinine',
              icon: Icons.science,
              field: 'creatinine',
              unit: 'mg/dL',
              latestValue: latest['creatinine'],
              historyList: history['creatinine'] ?? [],
            ),
            _buildVitalSection(
              label: 'LDL',
              icon: Icons.heart_broken,
              field: 'ldl',
              unit: 'mg/dL',
              latestValue: latest['ldl'],
              historyList: history['ldl'] ?? [],
            ),
          ],
        ),
      ),
    );
  }

 Map<String, VitalRecord?> _latestPerVital(List<VitalRecord> records) {
  final Map<String, VitalRecord?> map = {
    'bloodSugar': null,
    'cholesterol': null,
    'creatinine': null,
    'ldl': null,
  };

  for (var r in records) {
    if (r.bloodSugar != null) {
      if (map['bloodSugar'] == null ||
          DateTime.parse(r.createdOn).isAfter(DateTime.parse(map['bloodSugar']!.createdOn))) {
        map['bloodSugar'] = r;
      }
    }
    if (r.cholesterol != null) {
      if (map['cholesterol'] == null ||
          DateTime.parse(r.createdOn).isAfter(DateTime.parse(map['cholesterol']!.createdOn))) {
        map['cholesterol'] = r;
      }
    }
    if (r.creatinine != null) {
      if (map['creatinine'] == null ||
          DateTime.parse(r.createdOn).isAfter(DateTime.parse(map['creatinine']!.createdOn))) {
        map['creatinine'] = r;
      }
    }
    if (r.ldl != null) {
      if (map['ldl'] == null ||
          DateTime.parse(r.createdOn).isAfter(DateTime.parse(map['ldl']!.createdOn))) {
        map['ldl'] = r;
      }
    }
  }

  return map;
}

  Map<String, List<VitalRecord>> _historyGrouped(List<VitalRecord> records) {
    Map<String, List<VitalRecord>> grouped = {
      'bloodSugar': [],
      'cholesterol': [],
      'creatinine': [],
      'ldl': [],
    };

    for (var r in records.reversed) {
      if (r.bloodSugar != null) grouped['bloodSugar']!.add(r);
      if (r.cholesterol != null) grouped['cholesterol']!.add(r);
      if (r.creatinine != null) grouped['creatinine']!.add(r);
      if (r.ldl != null) grouped['ldl']!.add(r);
    }

    return grouped;
  }

  Widget _buildVitalSection({
    required String label,
    required IconData icon,
    required String field,
    required String unit,
    VitalRecord? latestValue,
    required List<VitalRecord> historyList,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF57C3FF), size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            Text(
              latestValue != null
                  ? '${_getVitalValue(latestValue, field)} $unit'
                  : '--',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                _expanded[field]! ? Icons.expand_less : Icons.expand_more,
                color: Colors.white54,
              ),
              onPressed: () => setState(() {
                _expanded[field] = !_expanded[field]!;
              }),
            )
          ],
        ),
        if (_expanded[field]!)
          Column(
            children: historyList.map((v) {
              final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(v.createdOn));
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                    '${_getVitalValue(v, field)} $unit',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            }).toList(),
          ),
        const Divider(color: Colors.white10, height: 24),
      ],
    );
  }

  dynamic _getVitalValue(VitalRecord r, String field) {
    switch (field) {
      case 'bloodSugar':
        return r.bloodSugar;
      case 'cholesterol':
        return r.cholesterol;
      case 'creatinine':
        return r.creatinine;
      case 'ldl':
        return r.ldl;
    }
    return '--';
  }

  void _showUpdateVitalDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _bloodSugarController = TextEditingController();
    final TextEditingController _cholesterolController = TextEditingController();
    final TextEditingController _creatinineController = TextEditingController();
    final TextEditingController _ldlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101B3C),
        title: const Text('Update Vitals', style: TextStyle(color: Colors.white)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildVitalField('Blood Sugar', _bloodSugarController),
                _buildVitalField('Cholesterol', _cholesterolController),
                _buildVitalField('Creatinine', _creatinineController),
                _buildVitalField('LDL', _ldlController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0064F4)),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final data = {
                if (_bloodSugarController.text.isNotEmpty) 'blood_sugar': double.parse(_bloodSugarController.text),
                if (_cholesterolController.text.isNotEmpty) 'cholesterol': double.parse(_cholesterolController.text),
                if (_creatinineController.text.isNotEmpty) 'creatine': double.parse(_creatinineController.text),
                if (_ldlController.text.isNotEmpty) 'ldl': double.parse(_ldlController.text),
                'test_date': DateTime.now().toIso8601String(),
              };

              try {
                final res = await ApiService().authenticatedPost('vital/vitals', body: data);
                if (res.statusCode == 200 || res.statusCode == 201) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vitals updated'),
                    backgroundColor: Colors.green,
                  ));
                } else {
                  throw Exception('Failed to update');
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildVitalField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        validator: (val) {
          if (val != null && val.isNotEmpty && double.tryParse(val) == null) return 'Invalid';
          return null;
        },
      ),
    );
  }
}
