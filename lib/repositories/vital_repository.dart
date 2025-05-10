import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/vital_model.dart';
import '../services/api_service.dart';

class VitalRepository {
  final _boxName = 'vitalsData';
  final _weightKey = 'weightData';
  final _vitalsKey = 'allVitals';
  final _syncKey = 'lastSync';
  final _apiService = ApiService();

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  Future<void> ensureHeightCached() async {
    final box = await _getBox();
    if (box.get('userHeight') == null) {
      final response = await _apiService.authenticatedGet('customer/user/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final heightStr = data['height']?.toString();
        final height = double.tryParse(heightStr ?? '');
        if (height != null && height > 0) {
          await box.put('userHeight', height);
        }
      }
    }
  }

  Future<List<WeightData>> fetchWeights(String period) async {
    final box = await _getBox();
    final response = await _apiService.authenticatedGet(
      'vital/vitals/weight-data',
      queryParameters: {'period': period},
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      final weights = list.map((e) => WeightData.fromJson(e)).toList();
      await box.put(_weightKey, weights.map((e) => e.toJson()).toList());
      await box.put(_syncKey, DateTime.now().toIso8601String());
      return weights;
    } else {
      throw Exception('Failed to fetch weights');
    }
  }

  Future<List<VitalRecord>> fetchVitals() async {
  final box = await _getBox();
  final response = await _apiService.authenticatedGet('vital/vitals');

  if (response.statusCode == 200) {
    final List<dynamic> list = jsonDecode(response.body);

    final vitals = list
        .map((e) => VitalRecord.fromJson(e))
        .where((v) =>
            v.bloodSugar != null ||
            v.cholesterol != null ||
            v.creatinine != null ||
            v.ldl != null)
        .toList(); // ✅ Filter non-empty records only

    await box.put(_vitalsKey, vitals.map((e) => e.toJson()).toList());
    return vitals;
  } else {
    throw Exception('Failed to fetch vitals');
  }
}


  Future<List<WeightData>> getCachedWeights() async {
    final box = await _getBox();
    final cached = box.get(_weightKey);
    if (cached is List) {
      return cached.map((e) => WeightData.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<VitalRecord>> getCachedVitals() async {
  final box = await _getBox();
  final cached = box.get(_vitalsKey);
  if (cached is List) {
    return cached
        .map((e) => VitalRecord.fromJson(Map<String, dynamic>.from(e)))
        .where((v) =>
            v.bloodSugar != null ||
            v.cholesterol != null ||
            v.creatinine != null ||
            v.ldl != null)
        .toList(); // ✅ Filter cached list too
  }
  return [];
}


  Future<void> saveWeight(double weight) async {
    await _apiService.authenticatedPost(
      'vital/vitals',
      body: {
        'weight': weight,
        'test_date': DateTime.now().toIso8601String(),
      },
    );
    final box = await _getBox();
    await box.delete(_syncKey); // Invalidate cache
  }
}
