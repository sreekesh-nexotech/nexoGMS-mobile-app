import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise_model.dart';
import '../../repositories/exercise_repository.dart';

final exerciseProvider = FutureProvider.family<List<ExerciseModel>, List<dynamic>>((ref, rawExercises) async {
  final repo = ExerciseRepository();
  return repo.getExercises(rawExercises);
});
