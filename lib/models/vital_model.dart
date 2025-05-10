class WeightData {
  final String date;
  final double weight;

  WeightData({required this.date, required this.weight});

  factory WeightData.fromJson(Map<String, dynamic> json) => WeightData(
        date: json['date'] ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'weight': weight,
      };
}

class VitalRecord {
  final String vitalsId;
  final double? bloodSugar;
  final double? cholesterol;
  final double? creatinine;
  final double? ldl;
  final String createdOn;

  VitalRecord({
    required this.vitalsId,
    this.bloodSugar,
    this.cholesterol,
    this.creatinine,
    this.ldl,
    required this.createdOn,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) => VitalRecord(
        vitalsId: json['vitals_id']?.toString() ?? '',
        bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
        cholesterol: (json['cholesterol'] as num?)?.toDouble(),
        creatinine: (json['creatine'] as num?)?.toDouble(),
        ldl: (json['ldl'] as num?)?.toDouble(),
        createdOn: json['created_on']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'vitals_id': vitalsId,
        'blood_sugar': bloodSugar,
        'cholesterol': cholesterol,
        'creatine': creatinine,
        'ldl': ldl,
        'created_on': createdOn,
      };
}
