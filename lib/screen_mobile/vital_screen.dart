import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'dart:convert';
import 'dart:math';
import '../services/hive_service.dart';

class VitalScreen extends StatefulWidget {
  @override
  _VitalScreenState createState() => _VitalScreenState();
}

class _VitalScreenState extends State<VitalScreen> {
  final ApiService _apiService = ApiService();
  List<WeightData> _weightData = [];
  List<VitalRecord> _allVitals = [];
  bool _isLoading = true;
  String _selectedPeriod = 'weekly';
  String? _errorMessage;
  bool _hasErrorPreviously = false;
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Box? _vitalsBox;
  //DateTime? _lastFullSync;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 INIT: Starting vitals screen');
    _initHive().then((_) {
      debugPrint('✅ HIVE: Initialization complete');
      _loadInitialData();
    });
  }

  Future<void> _initHive() async {
    try {
      debugPrint('📦 Opening vitalsData box...');
      await HiveService.openBox('vitalsData');
      _vitalsBox = Hive.box('vitalsData'); // Save it once
    } catch (e) {
      debugPrint('❌ HIVE ERROR: $e');
      setState(() {
        _errorMessage = 'Internal error. Please restart app.';
      });
    }
  }

  Future<void> _loadInitialData() async {
    debugPrint('🔍 LOAD: Checking cached data...');
    if (_vitalsBox?.get('userHeight') == null) {
      await _cacheUserHeight();
    }
    final cachedWeightData = _getCachedWeightData();
    final cachedVitals = _getCachedVitals();

    // Apply weekly filter to cached data immediately
    final initialWeightData = _applyPeriodFilter(cachedWeightData, 'weekly');

    if (mounted) {
      setState(() {
        _weightData = initialWeightData; // Show weekly data from cache first
        _allVitals = cachedVitals;
        _isLoading =
            cachedWeightData.isEmpty ||
            cachedVitals.isEmpty; // Only load if no cache
      });
    }

    // Load fresh data if needed (preserves your existing cache logic)
    if (cachedWeightData.isEmpty ||
        cachedVitals.isEmpty ||
        _hasErrorPreviously) {
      await _loadVitalsData();
    } else {
      // Just ensure period filter is applied to existing cache
      _filterDataForPeriod();
      await _checkForVitalsUpdates();
    }
    if (_vitalsBox?.get('userHeight') == null) {
      await _cacheUserHeight();
    }
  }

  List<WeightData> _applyPeriodFilter(List<WeightData> data, String period) {
    final now = DateTime.now();
    final cutoffDate =
        period == 'weekly'
            ? now.subtract(Duration(days: 7))
            : period == 'monthly'
            ? now.subtract(Duration(days: 30))
            : DateTime(1970);

    return data.where((item) {
      try {
        final date = DateTime.parse(item.date);
        return date.isAfter(cutoffDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _loadVitalsData({bool forceRefresh = false}) async {
    if (!mounted) return;

    debugPrint('🌐 LOAD: Starting network fetch...');
    setState(() => _isLoading = true);

    try {
      final lastSync = _vitalsBox?.get('lastSync');
      debugPrint('⏱️ SYNC: Last sync was $lastSync');

      if (forceRefresh || lastSync == null || _hasErrorPreviously) {
        debugPrint('🔄 SYNC: Doing full refresh');
        await _fullSync();
      } else {
        debugPrint('🔎 SYNC: Checking for updates');
        final needsUpdate = await _checkForUpdates(lastSync);
        if (needsUpdate) {
          debugPrint('🔄 SYNC: Doing delta update');
          await _deltaSync(lastSync);
        } else {
          debugPrint('✅ SYNC: Data is up-to-date');
        }
      }
      await _loadAllVitals();
    } catch (e) {
      debugPrint('❌ LOAD ERROR: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load updates';
          _hasErrorPreviously = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllVitals() async {
    try {
      debugPrint('🌐 Loading all vitals records...');
      final response = await _apiService.authenticatedGet('vital/vitals');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final vitals = data.map((item) => VitalRecord.fromJson(item)).toList();

        await _vitalsBox?.put(
          'allVitals',
          vitals.map((e) => e.toJson()).toList(),
        );
        await _vitalsBox?.put(
          'vitalsLastSync',
          DateTime.now().toIso8601String(),
        );

        if (mounted) {
          setState(() {
            _allVitals = vitals;
          });
        }
        debugPrint('✅ Loaded ${vitals.length} vitals records');
      } else {
        throw Exception('Failed to load vitals: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Vitals load error: $e');
      throw e;
    }
  }

  Future<bool> _checkForVitalsUpdates() async {
    try {
      final lastSync = _vitalsBox?.get('vitalsLastSync');
      if (lastSync == null) return true;

      final response = await _apiService.authenticatedGet(
        'vital/vitals/check-vitals-updates',
        queryParameters: {'since': lastSync},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasUpdates'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Vitals update check error: $e');
      return false;
    }
  }

  List<WeightData> _getCachedWeightData() {
    try {
      final cached = _vitalsBox?.get('weightData');
      if (cached != null && cached is List) {
        return cached.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return WeightData.fromJson(map);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ CACHE ERROR: $e');
      return [];
    }
  }

  List<VitalRecord> _getCachedVitals() {
    try {
      final cached = _vitalsBox?.get('allVitals');
      if (cached != null && cached is List) {
        return cached.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return VitalRecord.fromJson(map);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ VITALS CACHE ERROR: $e');
      return [];
    }
  }

  Future<bool> _checkForUpdates(String lastSync) async {
    try {
      final response = await _apiService.authenticatedGet(
        'vital/vitals/check-vitals-updates',
        queryParameters: {'since': lastSync},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasUpdates'] ?? false;
      }
      return true; // If check fails, assume updates exist
    } catch (e) {
      return false; // On error, use cached data
    }
  }

  Future<void> _fullSync() async {
    try {
      debugPrint('🌐 FULL SYNC: Fetching data...');
      final response = await _apiService.authenticatedGet(
        'vital/vitals/weight-data',
        queryParameters: {'period': _selectedPeriod},
      );

      if (!mounted) return;

      debugPrint('🌐 FULL SYNC: Response status ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📊 FULL SYNC: Received ${data.length} items');

        final updatedData =
            (data as List).map((item) => WeightData.fromJson(item)).toList();
        await _saveData(updatedData);

        if (!mounted) return; // Exit early if widget is no longer active
        setState(() {
          _weightData = updatedData;
          _filterDataForPeriod();
          _hasErrorPreviously = false;
        });
        debugPrint('🔄 FULL SYNC: Update complete');
      } else {
        throw Exception('Bad status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FULL SYNC ERROR: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sync data';
          _hasErrorPreviously = true;
        });
      }
      rethrow;
    }
  }

  Future<void> _deltaSync(String lastSync) async {
    try {
      final response = await _apiService.authenticatedGet(
        'vital/vitals-delta',
        queryParameters: {'since': lastSync},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<WeightData> updatedData =
            (data['vitals'] as List)
                .map((item) => WeightData.fromJson(item))
                .toList();

        final cachedData = _getCachedData();
        final mergedData = _mergeData(cachedData, updatedData);

        await _saveData(mergedData);
        if (!mounted) return; // Exit early if widget is no longer active
        setState(() {
          _weightData = mergedData;
          _hasErrorPreviously = false;
        });
      } else {
        throw Exception('Failed to load delta');
      }
    } catch (e) {
      throw e;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<WeightData> _getCachedData() {
    try {
      final cached = _vitalsBox?.get('weightData');
      if (cached != null && cached is List) {
        return cached.map((item) {
          // Convert dynamic map to String-keyed map
          final map = Map<String, dynamic>.from(item as Map);
          return WeightData.fromJson(map);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ CACHE ERROR: $e');
      return [];
    }
  }

  Future<void> _saveData(List<WeightData> data) async {
    await _vitalsBox?.put('weightData', data.map((e) => e.toJson()).toList());
    await _vitalsBox?.put('lastSync', DateTime.now().toIso8601String());
  }

  List<WeightData> _mergeData(
    List<WeightData> existing,
    List<WeightData> updates,
  ) {
    final merged = List<WeightData>.from(existing);

    for (final update in updates) {
      final index = merged.indexWhere((item) => item.date == update.date);
      if (index >= 0) {
        merged[index] = update;
      } else {
        merged.add(update);
      }
    }

    merged.sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  Future<void> _updateWeight() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.authenticatedPost(
        'vital/vitals',
        body: {
          'weight': double.parse(_weightController.text),
          'test_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'height': null,
          'blood_sugar': null,
          'cholesterol': null,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _weightController.clear();

        // Invalidate cache to force refresh on next load
        await _vitalsBox?.delete('lastSync');

        // Fetch fresh data
        await _loadVitalsData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Weight recorded successfully!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'Failed to save weight');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPeriodChip(String label, String period) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPeriod == period,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
          _filterDataForPeriod();
        }
      },
      selectedColor: Color(0xFF0064F4),
      labelStyle: TextStyle(
        color: _selectedPeriod == period ? Colors.black : Colors.white,
      ),
      backgroundColor: Colors.grey[800],
    );
  }

  double _calculateInterval() {
    final dataLength = _weightData.length;
    if (dataLength <= 7) return 1; // Daily
    if (dataLength <= 30) return 3; // Every 3 days
    if (dataLength <= 90) return 7; // Weekly
    return 30; // Monthly
  }

  void _filterDataForPeriod() {
    debugPrint('⏱ Filtering for $_selectedPeriod period');
    try {
      final now = DateTime.now();
      final cutoffDate =
          _selectedPeriod == 'weekly'
              ? now.subtract(Duration(days: 7))
              : _selectedPeriod == 'monthly'
              ? now.subtract(Duration(days: 30))
              : DateTime(1970);

      final allData = _getCachedData();
      final filtered =
          allData.where((item) {
            try {
              final date = DateTime.parse(item.date);
              return date.isAfter(cutoffDate);
            } catch (e) {
              return false; // Skip invalid dates
            }
          }).toList();

      if (mounted) {
        setState(() {
          _weightData = filtered;
          _isLoading = false; // Ensure loading is cleared
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add these methods to your existing state class
  Future<bool> _isWeightGainPlan() async {
    try {
      // 1. Check cached target weight from home screen
      final homeCache = await HiveService.openBox('home_cache');
      final cachedTarget = homeCache.get('targetWeight');

      if (cachedTarget != null && _weightData.isNotEmpty) {
        return _weightData.last.weight < cachedTarget;
      }

      // 2. Fallback to API if cache not available
      final response = await _apiService.authenticatedGet(
        'customer/target-weight',
      );
      if (response.statusCode == 200) {
        final target = jsonDecode(response.body)['target_weight']?.toDouble();
        return target != null && _weightData.isNotEmpty
            ? _weightData.last.weight < target
            : false;
      }
    } catch (e) {
      debugPrint('Target weight check error: $e');
    }
    return false; // Default to weight loss mode
  }

  Color _getTrendColor(double change, bool isGainPlan) {
    final isPositive = change > 0;
    return isPositive
        ? (isGainPlan ? Colors.green : Colors.red).withOpacity(0.3)
        : (isPositive ? Colors.red : Colors.green).withOpacity(0.3);
  }

  IconData _getTrendIcon(double change) {
    return change > 0
        ? Icons.trending_up
        : change < 0
        ? Icons.trending_down
        : Icons.trending_flat;
  }

  String _getTrendText(double change) {
    if (_weightData.length < 2) return 'No trend';
    return change > 0
        ? '+${change.toStringAsFixed(1)}kg'
        : change < 0
        ? '${change.toStringAsFixed(1)}kg'
        : 'No change';
  }

  double _calculateTrend() {
    if (_weightData.length < 2) return 0;
    return _weightData.last.weight - _weightData[_weightData.length - 2].weight;
  }

  Widget _buildVitalCard(VitalRecord vital) {
    final createdDate = DateTime.parse(vital.createdOn);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Color(0xFF1A2747),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(createdDate),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  DateFormat('hh:mm a').format(createdDate),
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            // if (vital.weight != null) _buildVitalRow('Weight', '${vital.weight} kg', Icons.monitor_weight),
            //if (vital.height != null) _buildVitalRow('Height', '${vital.height} cm', Icons.height),
            if (vital.bloodSugar != null)
              _buildVitalRow(
                'Blood Sugar',
                '${vital.bloodSugar} mg/dL',
                Icons.bloodtype,
              ),
            if (vital.cholesterol != null)
              _buildVitalRow(
                'Cholesterol',
                '${vital.cholesterol} mg/dL',
                Icons.favorite,
              ),
            if (vital.creatinine != null)
              _buildVitalRow(
                'Creatinine',
                '${vital.creatinine} mg/dL',
                Icons.science,
              ),
            if (vital.ldl != null)
              _buildVitalRow('LDL', '${vital.ldl} mg/dL', Icons.heart_broken),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF57C3FF)),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Calculate BMI using weight (kg) and height (cm)
  double? _calculateBMI() {
    if (_weightData.isEmpty) {
      debugPrint('⚠️ No weight data available');
      return null;
    }

    final latestWeight = _weightData.last.weight;
    final cachedHeight = _vitalsBox?.get('userHeight');

    // Handle case where height might be stored as string
    double? heightValue;
    if (cachedHeight is double) {
      heightValue = cachedHeight;
    } else if (cachedHeight is String) {
      heightValue = double.tryParse(cachedHeight);
    } else if (cachedHeight is int) {
      heightValue = cachedHeight.toDouble();
    }

    if (heightValue == null || heightValue <= 0) {
      debugPrint('⚠️ No valid height (current: $cachedHeight)');
      return null;
    }

    final heightM = heightValue / 100;
    final bmi = latestWeight / (heightM * heightM);
    debugPrint(
      '🧮 BMI Calculated: $latestWeight kg / ${heightValue}cm = ${bmi.toStringAsFixed(1)}',
    );
    return bmi;
  }

  String _getBMIStatus(double? bmi) {
    if (bmi == null) return 'N/A';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 23) return 'Normal'; // Adjusted for Asian standards
    if (bmi < 25) return 'Overweight (Asia)';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiStatusColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    return bmi < 18.5
        ? Colors.orange
        : bmi < 23
        ? Colors.green
        : bmi < 25
        ? Colors.orange
        : Colors.red;
  }

  Future<void> _cacheUserHeight() async {
    try {
      final response = await _apiService.authenticatedGet(
        'customer/user/profile',
      );
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        final heightStr =
            profileData['height']?.toString(); // Get as string first

        if (heightStr != null && heightStr.isNotEmpty) {
          final height = double.tryParse(heightStr); // Safely parse to double
          if (height != null) {
            await _vitalsBox?.put('userHeight', height);
            debugPrint('✅ Cached height from customer profile: $height cm');
          } else {
            debugPrint('⚠️ Invalid height format: $heightStr');
          }
        } else {
          debugPrint('⚠️ No height found in customer profile');
        }
      } else {
        debugPrint('❌ Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Profile height fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 BUILD: isLoading=$_isLoading, items=${_weightData.length}');
    debugPrint('📏 Cached height: ${_vitalsBox?.get('userHeight')}');
    debugPrint('⚖️ Weight data count: ${_weightData.length}');
    final bmi = _calculateBMI();
    final bmiStatus = _getBMIStatus(bmi);
    final bmiColor = _getBmiStatusColor(bmi);
    debugPrint('🧮 Calculated BMI: ${_calculateBMI()}');
    return Scaffold(
      backgroundColor: Color(0xFF081028),
      appBar: AppBar(
        title: Text(
          'Health Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Time Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodChip('Weekly', 'weekly'),
                  SizedBox(width: 8),
                  _buildPeriodChip('Monthly', 'monthly'),
                  SizedBox(width: 8),
                  _buildPeriodChip('All Time', 'all'),
                ],
              ),
            ),
            SizedBox(height: 5),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[200]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[200]),
                      ),
                    ),
                  ],
                ),
              ),

            // SizedBox(height: 20),

            // Weight Chart Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Color(0xFF0B1739),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weight Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_weightData.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FutureBuilder<bool>(
                                future: _isWeightGainPlan(),
                                builder: (context, snapshot) {
                                  final isGainPlan = snapshot.data ?? false;
                                  final change = _calculateTrend();
                                  return Row(
                                    children: [
                                      Text(
                                        '${_weightData.last.weight.toStringAsFixed(1)} kg ',
                                        style: TextStyle(
                                          color: Color(0xFF0064F4),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTrendColor(
                                            change,
                                            isGainPlan,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getTrendIcon(change),
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _getTrendText(change),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1A2747),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: bmiColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "BMI: ${bmi?.toStringAsFixed(1) ?? '--'}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      bmiStatus,
                                      style: TextStyle(
                                        color: bmiColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 200,
                      child:
                          _isLoading && _weightData.isEmpty
                              ? Center(child: CircularProgressIndicator())
                              : _weightData.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.insert_chart,
                                      size: 48,
                                      color: Colors.white54,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No weight records yet',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              )
                              : LineChart(
                                LineChartData(
                                  minY:
                                      _weightData
                                          .map((e) => e.weight)
                                          .reduce(min) -
                                      2,
                                  maxY:
                                      _weightData
                                          .map((e) => e.weight)
                                          .reduce(max) +
                                      2,
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    rightTitles: AxisTitles(),
                                    topTitles: AxisTitles(),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: _calculateInterval(),
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < _weightData.length) {
                                            final date = DateTime.parse(
                                              _weightData[index].date,
                                            );
                                            if (_selectedPeriod == 'weekly') {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  DateFormat('E').format(date),
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            } else if (_selectedPeriod ==
                                                'monthly') {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  DateFormat(
                                                    'd MMM',
                                                  ).format(date),
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              if (index % 3 == 0) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    DateFormat(
                                                      'MMM y',
                                                    ).format(date),
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Text('');
                                            }
                                          }
                                          return Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Text(
                                              '${value.toInt()} kg',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots:
                                          _weightData
                                              .asMap()
                                              .entries
                                              .map(
                                                (e) => FlSpot(
                                                  e.key.toDouble(),
                                                  e.value.weight,
                                                ),
                                              )
                                              .toList(),
                                      isCurved: true,
                                      color: Color(0xFF57C3FF),
                                      barWidth: 0.5,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF57C3FF).withOpacity(0.3),
                                            Color(0xFF0064F4).withOpacity(0.15),
                                            Color(0xFF0064F4).withOpacity(0.05),
                                            Colors.transparent,
                                          ],
                                          stops: [0.0, 0.3, 0.7, 1.0],
                                        ),
                                      ),
                                      dotData: FlDotData(show: false),
                                      shadow: Shadow(
                                        color: Color(
                                          0xFF0064F4,
                                        ).withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Weight Input Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Color(0xFF0B1739),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Record New Weight',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF0064F4).withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Weight (kg)',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(
                            Icons.monitor_weight,
                            color: Color(0xFF0064F4),
                          ),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null) {
                            return 'Enter a valid number';
                          }
                          if (weight <= 0 || weight > 300) {
                            return 'Enter weight between 0-300 kg';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0064F4),
                          foregroundColor: Colors.black,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                                : Text(
                                  'SAVE WEIGHT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_allVitals.isNotEmpty) ...[
              SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color(0xFF0B1739),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Records',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ..._allVitals
                          .where(
                            (vital) =>
                                // vital.height != null ||
                                vital.bloodSugar != null ||
                                vital.cholesterol != null ||
                                vital.creatinine != null ||
                                vital.ldl != null,
                          )
                          .map((vital) => _buildVitalCard(vital))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

  Map<String, dynamic> toJson() => {'date': date, 'weight': weight};
}

class VitalRecord {
  final String vitalsId;
  //final double? height;
  ///final double? weight;
  final double? bloodSugar;
  final double? cholesterol;
  final double? creatinine;
  final double? ldl;
  //final String testDate;
  final String createdOn;
  // final String lastUpdatedOn;

  VitalRecord({
    required this.vitalsId,
    // this.height,
    //this.weight,
    this.bloodSugar,
    this.cholesterol,
    this.creatinine,
    this.ldl,
    //required this.testDate,
    required this.createdOn,
    // required this.lastUpdatedOn,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord(
      vitalsId: json['vitals_id']?.toString() ?? '',
      //height: json['height']?.toDouble(),
      // weight: json['weight']?.toDouble(),
      bloodSugar: json['blood_sugar']?.toDouble(),
      cholesterol: json['cholesterol']?.toDouble(),
      creatinine: json['creatinine']?.toDouble(),
      ldl: json['ldl']?.toDouble(),
      //testDate: json['test_date']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      //lastUpdatedOn: json['last_updated_on']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'vitals_id': vitalsId,
    //'height': height,
    //'weight': weight,
    'blood_sugar': bloodSugar,
    'cholesterol': cholesterol,
    'creatinine': creatinine,
    'ldl': ldl,
    //'test_date': testDate,
    'created_on': createdOn,
    //'last_updated_on': lastUpdatedOn,
  };
}
