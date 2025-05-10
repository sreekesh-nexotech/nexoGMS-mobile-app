class Exercise {
  final String name;
  final int setCount;
  final int? repCount;
  final String? description;
  final String? videoUrl;

  Exercise({
    required this.name,
    required this.setCount,
    this.repCount,
    this.description,
    this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'],
        setCount: json['set_count'],
        repCount: json['rep_count'],
        description: json['description'],
        videoUrl: json['video_mapping'],
      );
      Map<String, dynamic> toJson() => {
        'name': name,
        'set_count': setCount,
        'rep_count': repCount,
        'description': description,
        'video_mapping': videoUrl,
      };
}

class WorkoutDay {
  final int id;
  final String name;
  final List<Exercise> exercises;

  WorkoutDay({
    required this.id,
    required this.name,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        id: json['exercise_group_id'],
        name: json['name'],
        exercises: (json['exercises'] as List)
            .map((e) => Exercise.fromJson(e))
            .toList(),
      );

      Map<String, dynamic> toJson() => {
        'exercise_group_id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
