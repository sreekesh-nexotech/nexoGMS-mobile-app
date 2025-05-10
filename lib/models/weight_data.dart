class WeightData {
  final String date;
  final double weight;

  WeightData({required this.date, required this.weight});

  factory WeightData.fromJson(Map<String, dynamic> json) {
    return WeightData(
      date: json['date'] ?? DateTime.now().toIso8601String(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'weight': weight,
      };
}
