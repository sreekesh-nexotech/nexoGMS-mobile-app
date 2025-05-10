class ExerciseModel {
  final String name;
  final int setCount;
  final int? repCount;
  final String? description;
  final String? videoUrl;

  ExerciseModel({
    required this.name,
    required this.setCount,
    this.repCount,
    this.description,
    this.videoUrl,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      name: json['name'] ?? '',
      setCount: json['set_count'] ?? 0,
      repCount: json['rep_count'],
      description: json['description'],
      videoUrl: json['video_mapping'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'set_count': setCount,
      'rep_count': repCount,
      'description': description,
      'video_mapping': videoUrl,
    };
  }
}
