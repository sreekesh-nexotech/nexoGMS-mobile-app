//import 'package:hive/hive.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  Future<List<ExerciseModel>> getExercises(List<dynamic> rawList) async {
    return rawList.map((e) => ExerciseModel.fromJson(e)).toList();
  }
}
