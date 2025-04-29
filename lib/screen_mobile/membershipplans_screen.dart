import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/hive_service.dart'; //Added by sreekesh

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  _MembershipPlansScreenState createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _plans = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastUpdated;
  Box? _cacheBox;

  // Cache constants
  final String _plansCacheKey = 'available_plans';
  final String _plansLastSyncKey = 'plans_last_sync';
  final String _plansLastUpdatedKey = 'plans_last_updated';

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadPlans();
  }

  Future<void> _initializeCacheAndLoadPlans() async {
    await HiveService.openBox('membership_plans_cache');
    _cacheBox = Hive.box('membership_plans_cache');
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    // Try to load from cache first
    final cachedPlans = await _getCachedPlans();
    if (cachedPlans != null) {
      setState(() {
        _plans = cachedPlans;
        _isLoading = false;
      });

      // Check for updates in background
      _checkForUpdates();
    } else {
      // No cache exists, fetch full data
      await _fetchFullPlans();
    }
  }

  Future<List<dynamic>?> _getCachedPlans() async {
    final cachedData = _cacheBox?.get(_plansCacheKey);
    if (cachedData == null) return null;

    final lastSync = _cacheBox?.get(_plansLastSyncKey);
    if (lastSync == null) return null;

    return jsonDecode(cachedData);
  }

  Future<void> _cachePlans(List<dynamic> plans, DateTime lastUpdated) async {
    await _cacheBox?.putAll({
      _plansCacheKey: jsonEncode(plans),
      _plansLastSyncKey: DateTime.now().toIso8601String(),
      _plansLastUpdatedKey: lastUpdated.toIso8601String(),
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      // final box = Hive.box('membership_plans_cache');
      final lastUpdated = _cacheBox?.get(_plansLastUpdatedKey);

      if (lastUpdated == null) {
        await _fetchFullPlans();
        return;
      }

      final response = await _apiService.authenticatedGet(
        'plans/check-plans-updates?since=${Uri.encodeComponent(lastUpdated)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasUpdates'] == true) {
          await _fetchDeltaPlans(lastUpdated);
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
      // If update check fails, we'll just use the cached data
    }
  }

  Future<void> _fetchFullPlans() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _apiService.authenticatedGet('plans/plans-full');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lastUpdated = DateTime.parse(data['lastUpdated']);
        setState(() {
          _plans = data['plans'] ?? [];
          _lastUpdated = lastUpdated;
          _isLoading = false;
        });
        await _cachePlans(_plans, lastUpdated);
      } else {
        throw ApiException('Failed to load plans', response.statusCode);
      }
    } on ApiException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.message;
        _isLoading = false;
      });

      // Even on error, try to show cached data if available
      final cachedPlans = await _getCachedPlans();
      if (cachedPlans != null) {
        setState(() {
          _plans = cachedPlans;
          _hasError = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });

      // Even on error, try to show cached data if available
      final cachedPlans = await _getCachedPlans();
      if (cachedPlans != null) {
        setState(() {
          _plans = cachedPlans;
          _hasError = false;
        });
      }
    }
  }

  Future<void> _fetchDeltaPlans(String since) async {
    try {
      final response = await _apiService.authenticatedGet(
        'plans/plans-delta?since=${Uri.encodeComponent(since)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lastUpdated = DateTime.parse(data['lastUpdated']);
        final deltaPlans = data['plans'] ?? [];

        // Merge delta with existing plans
        final Map<String, dynamic> planMap = {
          for (var plan in _plans) plan['membership_plan_id'].toString(): plan,
        };

        for (var deltaPlan in deltaPlans) {
          planMap[deltaPlan['membership_plan_id'].toString()] = deltaPlan;
        }

        final mergedPlans = planMap.values.toList();

        setState(() {
          _plans = mergedPlans;
          _lastUpdated = lastUpdated;
        });

        await _cachePlans(mergedPlans, lastUpdated);
      }
    } catch (e) {
      print('Error fetching delta plans: $e');
      // If delta fails, fall back to full refresh
      await _fetchFullPlans();
    }
  }

  Future<void> _refreshPlans() async {
    // Always do a full refresh when user manually refreshes
    await _fetchFullPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: Color(0xFF081028),
        title: const Text(
          'Available Membership Plans',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPlans,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _plans.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0064F4)),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0064F4),
              ),
              onPressed: _refreshPlans,
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return const Center(
        child: Text(
          'No available membership plans',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'] ?? 'Unnamed Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF0064F4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF0064F4), width: 1),
                  ),
                  child: Text(
                    '${plan['period']} months',
                    style: const TextStyle(
                      color: Color(0xFF0064F4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan['description'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  plan['description'],
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                Text(
                  currencyFormat.format(plan['amount']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFAEB9E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  //  _showEnrollmentRequestDialog(plan);
                },
                child: const Text(
                  'REQUEST ENROLLMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  //Future<void> _showEnrollmentRequestDialog(Map<String, dynamic> plan) async {
  // final result = await showDialog<bool>(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     backgroundColor: Colors.grey[900],
  //    title: Text(
  //     'Request Enrollment',
  //     style: const TextStyle(color: Colors.white),
  //   ),
  //  content: Text(
  //    'Your request for ${plan['name']} membership will be sent to the gym admin. '
  //   'They will contact you shortly to complete the enrollment process.',
  //   style: TextStyle(color: Colors.white.withOpacity(0.8)),
  //  ),
  //  actions: [
  //   TextButton(
  //    child: const Text('Cancel',
  //        style: TextStyle(color: Colors.white)),
  //   onPressed: () => Navigator.of(context).pop(false),
  //   ),
  //   ElevatedButton(
  //     style: ElevatedButton.styleFrom(
  //      backgroundColor: Color(0xFF0064F4),
  //  ),
  //    child: const Text('Send Request',
  //        style: TextStyle(color: Colors.black)),
  //    onPressed: () => Navigator.of(context).pop(true),
  //    ),
  //    ],
  //   ),
  //  );

  //  if (result == true) {
  // //   _sendEnrollmentRequest(plan['membership_plan_id']);
  //   }
  // }

  // Future<void> _sendEnrollmentRequest(int planId) async {
  //  try {
  //   final response = await _apiService.authenticatedPost(
  //     'customer/membership-plans/request-enrollment',
  //     body: {'membership_plan_id': planId},
  //    );

  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  // /        content: Text('Enrollment request sent successfully!'),
  //       backgroundColor: Colors.green,
  //      ),
  //       );
  //   } else {
  //      throw ApiException('Failed to send request', response.statusCode);
  //     }
  //   } on ApiException catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.message),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  /////   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('An error occurred while sending request'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
}
