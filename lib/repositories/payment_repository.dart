import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentRepository {
  final _boxName = 'payment_cache';
  final _cacheKey = 'payments';
  final _apiService = ApiService();

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  Future<List<PaymentModel>> getCachedPayments() async {
    final box = await _getBox();
    final cached = box.get(_cacheKey);
    if (cached != null && cached is List) {
      return cached.map((e) => PaymentModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<void> savePayments(List<PaymentModel> payments) async {
    final box = await _getBox();
    await box.put(_cacheKey, payments.map((e) => e.toJson()).toList());
  }

  Future<List<PaymentModel>> fetchPayments() async {
    final response = await _apiService.authenticatedGet('payment/payments');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PaymentModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch payments');
    }
  }
}
