import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
//import 'attendance_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_screen.dart';
import 'api_service.dart';
import 'payment_screen.dart';
import 'vital_screen.dart';
import 'membershipplans_screen.dart';
import 'exercise_screen.dart';
import 'Cache_Manager.dart';
import '../services/hive_service.dart'; //Added by sreekesh

// Cache constants
const String _homeCacheBox = 'home_cache';
const String _weightCacheBox = 'weight_data';
const String _gymStreakCacheKey = 'gym_streak';
const String _feeDueDateCacheKey = 'fee_due_date';
const String _membershipPlanCacheKey = 'membership_plan';
const String _lastSyncKey = 'last_sync';
//const String _lastChangesKey = 'last_changes';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({required this.username, super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _gymStreak = 0;
  bool _isLoadingStreak = true;
  DateTime? _feeDueDate;
  bool _isLoadingFee = true;
  String _membershipPlanName = 'Loading...';
  String _membershipPlanPeriod = '';
  String _membershipPlanAmount = '';
  bool _isMembershipActive = false;
  bool _isLoadingMembership = true;
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _todaysWorkout;
  bool _isLoadingWorkout = true;
  int _totalGymDays = 0;
  bool _isLoadingTotalDays = true;
  double _currentWeight = 0.0;
  double _targetWeight = 0.0;
  bool _isLoadingWeight = true;
  Box? _homeCache;
  Box? _weightCache;

  // Cache-related variables
  bool _isFirstLoad = true;
  //DateTime? _lastSyncTime;
  Map<String, dynamic>? _lastKnownChanges;

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _fetchTodaysWorkout();
    _fetchTotalGymDays();
    _fetchWeightData();
    _fetchTargetWeight();
  }

  Future<void> _initializeCache() async {
    await HiveService.openBox(_homeCacheBox);
    await HiveService.openBox(_weightCacheBox);
    _homeCache = Hive.box(_homeCacheBox);
    _weightCache = Hive.box(_weightCacheBox);
    _loadInitialData();
  }

  Future<void> _fetchWeightData({bool forceRefresh = false}) async {
    setState(() => _isLoadingWeight = true);

    try {
      final lastSync = _weightCache?.get('lastSync');

      // First load or forced refresh
      if (forceRefresh || lastSync == null) {
        await _fetchLatestWeight();
      }
      // Subsequent loads with change check
      else {
        final hasUpdates = await _checkWeightUpdates(lastSync);
        if (hasUpdates) {
          await _fetchLatestWeight();
        } else {
          _loadCachedWeight();
        }
      }
    } catch (e) {
      debugPrint('Weight sync error: $e');
      _loadCachedWeight(); // Fallback to cache
    } finally {
      if (mounted) setState(() => _isLoadingWeight = false);
    }
  }

  Future<bool> _checkWeightUpdates(String lastSync) async {
    try {
      final response = await _apiService.authenticatedGet(
        'vital/vitals/check-vitals-updates',
        queryParameters: {'since': lastSync},
      );
      return jsonDecode(response.body)['hasUpdates'] ?? true;
    } catch (e) {
      debugPrint('Update check error: $e');
      return true; // Assume updates if check fails
    }
  }

  Future<void> _fetchLatestWeight() async {
    final response = await _apiService.authenticatedGet(
      'vital/vitals/current-weight',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        await _saveWeightData(
          weight: data['weight'],
          lastUpdated: data['last_updated'],
        );
      }
    }
  }

  void _loadCachedWeight() {
    final weight = _weightCache?.get('currentWeight', defaultValue: 0.0);
    setState(() => _currentWeight = weight);
  }

  Future<void> _saveWeightData({
    required double weight,
    required String lastUpdated,
  }) async {
    await _weightCache?.putAll({
      'currentWeight': weight,
      'lastUpdated': lastUpdated,
      'lastSync': DateTime.now().toIso8601String(),
    });
    setState(() => _currentWeight = weight);
  }

  Future<void> _fetchTargetWeight() async {
    try {
      final response = await _apiService.authenticatedGet(
        'customer/target-weight',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _targetWeight = (data['target_weight'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      print('Error fetching target weight: $e');
    }
  }

  Future<void> _fetchTotalGymDays() async {
    setState(() => _isLoadingTotalDays = true);
    try {
      final response = await _apiService.authenticatedGet(
        'workout/total-gym-days',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _totalGymDays = data['total_days'] ?? 0);
      }
    } catch (e) {
      print('Error fetching total gym days: $e');
    } finally {
      setState(() => _isLoadingTotalDays = false);
    }
  }

  Future<void> _fetchTodaysWorkout() async {
    setState(() => _isLoadingWorkout = true);
    try {
      final response = await _apiService.authenticatedGet('workout/workouts');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final workouts = data['workouts'] ?? [];

        // Simple logic: Use weekday to determine today's workout
        final dayIndex = DateTime.now().weekday % workouts.length;
        setState(
          () =>
              _todaysWorkout = workouts.isNotEmpty ? workouts[dayIndex] : null,
        );
      }
    } catch (e) {
      print('Error fetching workouts: $e');
    } finally {
      setState(() => _isLoadingWorkout = false);
    }
  }

  void _navigateToTodaysWorkout() {
    if (_todaysWorkout == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExerciseScreen(
              day: "Today's Workout",
              bodyPart: _todaysWorkout!['name'] ?? 'Workout',
              exercises: _todaysWorkout!['exercises'] ?? [],
            ),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    // Load from cache first
    final cachedData = await _getCachedData();
    final hasCache = cachedData != null;

    // Check for changes if we have cache
    if (hasCache) {
      await _checkForChanges();
    }

    // Determine if we need to force refresh
    final forceRefresh =
        !hasCache || _isFirstLoad || _hasRelevantChanges() || _isCacheExpired();

    if (forceRefresh) {
      // Full fetch if no cache or changes detected
      await Future.wait([
        _fetchGymStreak(forceRefresh: forceRefresh),
        _fetchFeeDueDate(forceRefresh: forceRefresh),
        _fetchMembershipPlan(forceRefresh: forceRefresh),
      ]);
      _isFirstLoad = false;
    } else {
      // Use cached data
      _applyCachedData(cachedData);
    }
  }

  Future<Map<String, dynamic>?> _getCachedData() async {
    final box = _homeCache?.get(_homeCacheBox);
    if (box.isEmpty) return null;

    return {
      'gym_streak': box.get(_gymStreakCacheKey),
      'fee_due_date': box.get(_feeDueDateCacheKey),
      'membership_plan': box.get(_membershipPlanCacheKey),
      'last_sync': box.get(_lastSyncKey),
    };
  }

  void _applyCachedData(Map<String, dynamic> cachedData) {
    setState(() {
      _gymStreak = cachedData['gym_streak'] ?? 0;
      _feeDueDate =
          cachedData['fee_due_date'] != null
              ? DateTime.parse(cachedData['fee_due_date'])
              : null;

      if (cachedData['membership_plan'] != null) {
        final plan = jsonDecode(cachedData['membership_plan']);
        _membershipPlanName = plan['plan_name'] ?? 'No plan';
        _membershipPlanPeriod =
            plan['period'] != null ? '${plan['period']} months' : '';
        _membershipPlanAmount =
            plan['amount'] != null ? '₹${plan['amount']}' : '';
        _isMembershipActive = plan['is_active'] ?? false;
      }

      _isLoadingStreak = false;
      _isLoadingFee = false;
      _isLoadingMembership = false;
    });
  }

  Future<Set<String>?> _checkForChanges() async {
    try {
      final response = await _apiService.authenticatedGet(
        'customer/check-changes-in-all',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastKnownChanges = data;

        // Parse changed tables into a Set for easy checking
        final changedTables = data['changed_tables']?.toString() ?? '';
        return {
          if (changedTables.contains('vitals')) 'vitals',
          if (changedTables.contains('workouts')) 'workouts',
          if (changedTables.contains('attendance') ||
              changedTables.contains('gym_sessions'))
            'gym_data',
          if (changedTables.contains('membership_plan') ||
              changedTables.contains('payments'))
            'membership',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Change check error: $e');
      return null; // Return null to indicate we should do full refresh
    }
  }

  bool _hasRelevantChanges() {
    if (_lastKnownChanges == null) return false;

    final changedTables =
        _lastKnownChanges!['changed_tables']?.toString() ?? '';
    return changedTables.contains('membership_plan') ||
        changedTables.contains('customer');
  }

  bool _isCacheExpired() {
    final lastSync = _homeCache?.get(_lastSyncKey);
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.parse(lastSync);
    return DateTime.now().difference(lastSyncTime) > Duration(hours: 24);
  }

  Future<void> _cacheCurrentData() async {
    // final box = Hive.box(_homeCacheBox);
    await _homeCache?.putAll({
      _gymStreakCacheKey: _gymStreak,
      _feeDueDateCacheKey: _feeDueDate?.toIso8601String(),
      _membershipPlanCacheKey: jsonEncode({
        'plan_name': _membershipPlanName,
        'period': _membershipPlanPeriod.replaceAll(' months', ''),
        'amount': _membershipPlanAmount.replaceAll('₹', ''),
        'is_active': _isMembershipActive,
      }),
      _lastSyncKey: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _fetchGymStreak({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedStreak = _homeCache?.get(_gymStreakCacheKey);
      if (cachedStreak != null) {
        setState(() {
          _gymStreak = cachedStreak;
          _isLoadingStreak = false;
        });
        return;
      }
    }

    setState(() => _isLoadingStreak = true);
    try {
      final response = await _apiService.authenticatedGet('workout/gym-streak');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gymStreak = data['streak'] ?? 0;
          _isLoadingStreak = false;
        });
        await _homeCache?.put(_gymStreakCacheKey, _gymStreak);
      } else {
        throw ApiException('Failed to load streak', response.statusCode);
      }
    } on ApiException catch (e) {
      setState(() => _isLoadingStreak = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      setState(() => _isLoadingStreak = false);
      print('Error fetching gym streak: $e');
    }
  }

  Future<void> _fetchFeeDueDate({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedDate = _homeCache?.get(_feeDueDateCacheKey);
      if (cachedDate != null) {
        setState(() {
          _feeDueDate = DateTime.parse(cachedDate);
          _isLoadingFee = false;
        });
        return;
      }
    }

    setState(() => _isLoadingFee = true);
    try {
      final response = await _apiService.authenticatedGet(
        'customer/fee-due-date',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _feeDueDate =
              data['fee_due_date'] != null
                  ? DateTime.parse(data['fee_due_date'])
                  : null;
          _isLoadingFee = false;
        });
        await _homeCache?.put(
          _feeDueDateCacheKey,
          _feeDueDate?.toIso8601String(),
        );
      } else {
        throw ApiException('Failed to load due date', response.statusCode);
      }
    } on ApiException catch (e) {
      setState(() => _isLoadingFee = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      setState(() => _isLoadingFee = false);
      print('Error fetching fee due date: $e');
    }
  }

  Future<void> _fetchMembershipPlan({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedPlan = _homeCache?.get(_membershipPlanCacheKey);
      if (cachedPlan != null) {
        final data = jsonDecode(cachedPlan);
        setState(() {
          _membershipPlanName = data['plan_name'] ?? 'No plan';
          _membershipPlanPeriod =
              data['period'] != null ? '${data['period']} months' : '';
          _membershipPlanAmount =
              data['amount'] != null ? '₹${data['amount']}' : '';
          _isMembershipActive = data['is_active'] ?? false;
          _isLoadingMembership = false;
        });
        return;
      }
    }

    setState(() => _isLoadingMembership = true);
    try {
      final response = await _apiService.authenticatedGet(
        'customer/customer/flutter/membership-plan',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _membershipPlanName = data['plan_name'] ?? 'No plan';
          _membershipPlanPeriod =
              data['period'] != null ? '${data['period']} months' : '';
          _membershipPlanAmount =
              data['amount'] != null ? '₹${data['amount']}' : '';
          _isMembershipActive = data['is_active'] ?? false;
          _isLoadingMembership = false;
        });
        await _homeCache?.put(
          _membershipPlanCacheKey,
          jsonEncode({
            'plan_name': _membershipPlanName,
            'period': data['period'],
            'amount': data['amount'],
            'is_active': _isMembershipActive,
          }),
        );
      } else {
        throw ApiException('Failed to load membership', response.statusCode);
      }
    } on ApiException catch (e) {
      setState(() {
        _membershipPlanName = 'Error: ${e.message}';
        _isLoadingMembership = false;
      });
    } catch (e) {
      setState(() {
        _membershipPlanName = 'Error loading plan';
        _isLoadingMembership = false;
      });
    }
  }

  ///String _calculateDaysRemaining(DateTime dueDate) {
  // final today = DateTime.now();
  // final difference = dueDate.difference(today).inDays;

  // if (difference < 0) {
  //    return 'Overdue by ${difference.abs()} days';
  //  } else if (difference == 0) {
  //    return 'Due today';
  //  } else {
  ////     return '$difference days remaining';
  //   }
  // }

  Color _getDueDateColor(DateTime dueDate) {
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    Navigator.pop(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[800],
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await _performLogout(context);
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await _apiService.logout();
      await CacheManager.clearAllCache();
      _navigateToLogin(context);
    } catch (e) {
      print('Logout error: $e');
      await CacheManager.clearAllCache();
      _navigateToLogin(context);
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _refreshAllData, // New method we'll create
        color: Color(0xFF0064F4),
        backgroundColor: Color(0xFF0B1739),
        displacement: 40,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingSection(),
              const SizedBox(height: 18),
              _buildTodaysWorkoutBox(),
              const SizedBox(height: 40),
              _buildStatsGrid(),
              // const SizedBox(height: 18),
              _buildWeightStats(),
              const SizedBox(height: 30),
              _buildMembershipDetailsSection(),
              const SizedBox(height: 60),
              //_buildMembershipCard(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAllData() async {
    try {
      // First check for any changes
      final changes = await _checkForChanges();

      // Only fetch data that has changed
      await Future.wait([
        if (changes?.contains('vitals') ?? true)
          _fetchWeightData(forceRefresh: true),
        if (changes?.contains('workouts') ?? true) _fetchTodaysWorkout(),
        if (changes?.contains('gym_data') ?? true) ...[
          _fetchTotalGymDays(),
          _fetchGymStreak(forceRefresh: true),
        ],
        if (changes?.contains('membership') ?? true) ...[
          _fetchFeeDueDate(forceRefresh: true),
          _fetchMembershipPlan(forceRefresh: true),
        ],
      ]);

      // Update last sync time
      await _cacheCurrentData();
    } catch (e) {
      debugPrint('Refresh error: $e');
      // Fallback to full refresh if change check fails
      await _forceFullRefresh();
    }
  }

  Future<void> _forceFullRefresh() async {
    await Future.wait([
      _fetchWeightData(forceRefresh: true),
      _fetchTargetWeight(),
      _fetchTodaysWorkout(),
      _fetchTotalGymDays(),
      _fetchGymStreak(forceRefresh: true),
      _fetchFeeDueDate(forceRefresh: true),
      _fetchMembershipPlan(forceRefresh: true),
    ]);
  }

  Widget _buildGreetingSection() {
    // Extract first name from the full username
    String firstName = widget.username.split(' ').first;

    return Container(
      width: 350, // Matches Figma layout width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Hey [Name]!" part

          // padding: const EdgeInsets.only(top: 40), // Y:40 in Figma (assuming 0 is top of screen)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Hey ',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              Text(
                '$firstName!',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),

          // Subtitle text with exact Y position
          Padding(
            padding: const EdgeInsets.only(
              top: 6,
            ), // 84 (total Y) - 40 (greeting Y) - 28 (greeting font size ≈ line height)
            child: const Text(
              "Ready to crush your next workout and hit those fitness goals? Let's get moving!",
              style: TextStyle(
                fontFamily: 'WorkSans',
                color: Color(0xFFFFFFFF),
                fontSize: 24,
                height: 1.2, // Optional: adjust line height if needed
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkoutBox() {
    return Container(
      width: 362, // Exact box width
      height: 148, // Exact box height
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // TODAY'S WORKOUT text
          Positioned(
            left: 16, // From left border
            top: 16, // From top border
            child: SizedBox(
              width: 144, // Exact width
              height: 20, // Exact height
              child: Text(
                "Today's Workout",
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  height: 20 / 18, // Calculate line height
                  color: const Color(0xFFAEB9E1),
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Positioned(
            left: 233, // 362(width) - 112(image) - 17(right border) = 233
            top: 16,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/bird.png',
                  ), // Update with your image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Workout content
          if (_isLoadingWorkout)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0064F4)),
            )
          else if (_todaysWorkout == null)
            Positioned(
              left: 16, // From left border
              top: 46, // From top border
              child: SizedBox(
                width: 188, // Exact width
                height: 20, // Exact height
                child: Text(
                  'No workout scheduled',
                  style: TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    height: 20 / 18,
                    color: const Color(0xFFFFFFFF),
                    letterSpacing: 0,
                  ),
                ),
              ),
            )
          else ...[
            // Workout name
            Positioned(
              left: 16, // From left border
              top: 46, // From top border
              child: SizedBox(
                width: 188, // Exact width
                height: 20, // Exact height
                child: Text(
                  _todaysWorkout!['name'] ?? 'Workout',
                  style: TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    height: 20 / 18,
                    color: const Color(0xFFFFFFFF),
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),

            // VIEW WORKOUT button
            Positioned(
              left: 16, // From left border
              top: 86, // From top border
              child: SizedBox(
                width: 162, // Exact width
                height: 42, // Exact height
                child: ElevatedButton(
                  onPressed: _navigateToTodaysWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064F4),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets
                            .zero, // Using exact dimensions instead of padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'VIEW WORKOUT',
                    style: TextStyle(
                      fontSize: 13, // Adjusted for button height
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required bool isLoading,
    Color valueColor = Colors.white,
    double valueSize = 24.0,
    String? secondaryText,
    String? subtitle,
  }) {
    return SizedBox(
      width: 176, // Fixed card width
      height: 92, // Fixed card height
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1739),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12), // Internal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title - Dynamic but constrained
            SizedBox(
              width: 135, // Max width
              height: 20, // Fixed height
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14, // Base size
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Value + Secondary Text
                    SizedBox(
                      width: 95, // Max width
                      height: 32, // Fixed height
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: valueColor,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    valueSize, // Will scale down if needed
                              ),
                            ),
                            if (secondaryText != null) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  secondaryText,
                                  style: TextStyle(
                                    color: valueColor.withOpacity(0.8),
                                    fontSize: 14, // Base size
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Subtitle (only for fee due date)
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 150, // Slightly less than card width
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: valueColor.withOpacity(0.8),
                              fontSize: 12, // Smaller fixed size
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Updated grid widgets to maintain proper aspect ratio
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 176 / 92, // Proper aspect ratio
      children: [
        _buildStatCard(
          title: 'Total Gym Days',
          value: _isLoadingTotalDays ? '--' : '$_totalGymDays',
          secondaryText: '  Days',
          isLoading: _isLoadingTotalDays,
          valueSize: 29.0,
        ),
        _buildStatCard(
          title: 'Gym Streak',
          value: _isLoadingStreak ? '--' : '$_gymStreak',
          secondaryText: '  Days',
          isLoading: _isLoadingStreak,
          valueSize: 29.0,
        ),
      ],
    );
  }

  Widget _buildWeightStats() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 176 / 92, // Proper aspect ratio
        children: [
          _buildStatCard(
            title: 'Target Weight',
            value:
                _isLoadingWeight
                    ? '--'
                    : '${_targetWeight.toStringAsFixed(1)} ',
            secondaryText: 'Kg',
            isLoading: _isLoadingWeight,
            valueSize: 24.0,
          ),
          _buildStatCard(
            title: 'Current Weight',
            value:
                _isLoadingWeight
                    ? '--'
                    : '${_currentWeight.toStringAsFixed(1)} ',
            secondaryText: 'Kg',
            isLoading: _isLoadingWeight,
            valueSize: 24.0,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 10),
          child: Text(
            'Membership Details',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 176 / 92, // Proper aspect ratio
          children: [
            _buildStatCard(
              title: 'Membership Type',
              value: _isLoadingMembership ? '--' : _membershipPlanName,
              isLoading: _isLoadingMembership,
              valueSize: 15.0,
            ),
            _buildStatCard(
              title: 'FEE DUE DATE',
              value:
                  _isLoadingFee
                      ? '--'
                      : _feeDueDate == null
                      ? 'N/A'
                      : '${_feeDueDate!.day}/${_feeDueDate!.month}/${_feeDueDate!.year}',
              //subtitle: _isLoadingFee || _feeDueDate == null ? null :
              //   _calculateDaysRemaining(_feeDueDate!),
              isLoading: _isLoadingFee,
              valueColor:
                  _feeDueDate != null
                      ? _getDueDateColor(_feeDueDate!)
                      : Colors.white,
              valueSize: 15.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B1739),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF080F27)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.username,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.white),
            title: const Text(
              'Membership Plans',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MembershipPlansScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.white),
            title: const Text(
              'Payments',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentsScreen()),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.white),
            title: const Text(
              'Gym Reports',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              final shouldRefresh = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => VitalScreen()),
              );
              if (shouldRefresh ?? false) {
                _fetchWeightData(); // Refresh current weight
              }
            },
          ),
          // Removed Spacer() to prevent grey space
          const Divider(color: Colors.grey),
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0064F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
