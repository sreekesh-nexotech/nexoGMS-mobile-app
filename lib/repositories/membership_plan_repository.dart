import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/membership_plan_model.dart';
import '../services/api_service.dart';

class MembershipPlanRepository {
  final _boxName = 'membership_plans_cache';
  final _cacheKey = 'available_plans';
  final _syncKey = 'plans_last_sync';
  final _updatedKey = 'plans_last_updated';
  final _apiService = ApiService();

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  Future<List<MembershipPlan>> fetchPlans() async {
    final box = await _getBox();
    final response = await _apiService.authenticatedGet('plans/plans-full');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List plans = data['plans'];
      final lastUpdated = data['lastUpdated'];
      await box.putAll({
        _cacheKey: jsonEncode(plans),
        _syncKey: DateTime.now().toIso8601String(),
        _updatedKey: lastUpdated,
      });
      return plans.map((e) => MembershipPlan.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch membership plans');
    }
  }

  Future<List<MembershipPlan>> getCachedPlans() async {
    final box = await _getBox();
    final cached = box.get(_cacheKey);
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => MembershipPlan.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> clearCache() async {
    final box = await _getBox();
    await box.clear();
  }
}
