import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _payments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _errorOccurred = false;
  late Box _paymentCacheBox;
  DateTime? _lastUpdated;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeHiveAndData();
  }

  Future<void> _initializeHiveAndData() async {
    try {
      _paymentCacheBox = await Hive.openBox('payment_cache');
      await _loadCachedPayments();
      
      // Use different strategy based on first load or not
      if (_isFirstLoad) {
        await _fetchFullPayments();
        _isFirstLoad = false;
      } else {
        await _checkForUpdates();
      }
    } catch (e) {
      print('Error initializing: $e');
      setState(() {
        _isLoading = false;
        _errorOccurred = true;
      });
    }
  }

  Future<void> _loadCachedPayments() async {
    final cachedData = _paymentCacheBox.get('payments');
    if (cachedData != null) {
      setState(() {
        _payments = cachedData['data'];
        _lastUpdated = DateTime.parse(cachedData['lastUpdated']);
      });
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      if (_lastUpdated == null) {
        // If no cache exists, fall back to full refresh
        await _fetchFullPayments();
        return;
      }

      final response = await _apiService.authenticatedGet(
        'payment/check-payments-updates?since=${_lastUpdated!.toIso8601String()}'
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['hasUpdates']) {
          await _fetchDeltaPayments();
        } else {
          // No updates - use cached data
          setState(() => _isLoading = false);
          if (_isRefreshing) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payments are up to date'),
                backgroundColor: Colors.blue,
              ),
            );
            setState(() => _isRefreshing = false);
          }
        }
      } else {
        throw Exception('Failed to check updates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking updates: $e');
      // On error, fall back to cached data
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorOccurred = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check for updates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _fetchFullPayments() async {
  try {
    final response = await _apiService.authenticatedGet('payment/payments');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _updateCache(data, DateTime.now());
      
      // Show success feedback if this was a manual refresh
      if (_isRefreshing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payments refreshed'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      throw Exception('Failed to load payments: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching full payments: $e');
    throw e; // Re-throw to be caught by _checkForUpdates
  } finally {
    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }
}

  Future<void> _fetchDeltaPayments() async {
    try {
      final response = await _apiService.authenticatedGet(
        'payment/payments-delta?since=${_lastUpdated!.toIso8601String()}'
      );
      
      if (response.statusCode == 200) {
        final deltaData = jsonDecode(response.body);
        final updatedPayments = _mergeDeltaData(_payments, deltaData['payments']);
        await _updateCache(updatedPayments, DateTime.parse(deltaData['lastUpdated']));
      } else {
        // Fallback to full refresh if delta fails
        await _fetchFullPayments();
      }
    } catch (e) {
      print('Error fetching delta payments: $e');
      await _fetchFullPayments();
    }
  }

  List<dynamic> _mergeDeltaData(List<dynamic> existing, List<dynamic> delta) {
    final result = List<dynamic>.from(existing);
    
    for (final payment in delta) {
      final index = result.indexWhere((p) => p['payment_id'] == payment['payment_id']);
      if (index >= 0) {
        result[index] = payment; // Update existing
      } else {
        result.add(payment); // Add new
      }
    }
    
    // Sort by date descending
    result.sort((a, b) => DateTime.parse(b['transaction_date'])
        .compareTo(DateTime.parse(a['transaction_date'])));
    
    return result;
  }

  Future<void> _updateCache(List<dynamic> data, DateTime lastUpdated) async {
    await _paymentCacheBox.put('payments', {
      'data': data,
      'lastUpdated': lastUpdated.toIso8601String(),
    });
    
    setState(() {
      _payments = data;
      _lastUpdated = lastUpdated;
      _isLoading = false;
      _isRefreshing = false;
      _errorOccurred = false;
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String status) {
    final statusLower = status.toLowerCase();
    Color color;
    IconData icon;
    String text;

    switch (statusLower) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Paid';
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        text = 'Failed';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        text = 'Pending';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF0B1739),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }

  void _showPaymentDetailModal(Map<String, dynamic> payment) {
    final status = payment['status']?.toString().toLowerCase();
    final date = DateTime.parse(payment['transaction_date']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF0B1739),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0B1739),
                    ),
                    child: Icon(
                      Icons.receipt,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  'Amount', 
                  '₹${payment['amount']?.toStringAsFixed(2) ?? '0.00'}'
                ),
                _buildDetailRow(
                  'Payment ID', 
                  payment['payment_id'].toString()
                ),
                _buildDetailRow(
                  'Date', 
                  DateFormat('MMM dd, yyyy').format(date)
                ),
                _buildDetailRow(
                  'Time', 
                  DateFormat('hh:mm a').format(date)
                ),
                _buildDetailRow(
                  'Payment Method', 
                  payment['payment_method'] ?? 'N/A'
                ),
                _buildDetailRow(
                  'Description', 
                  payment['description'] ?? 'N/A'
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      _buildStatusBadge(payment['status']),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (status == 'pending' || status == 'failed') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade700),
                    ),
                    child: const Text(
                      'DOWNLOAD RECEIPT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load payments',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorOccurred = false;
              });
              _checkForUpdates();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 60,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment history',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
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
              )
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showPaymentDetailModal(payment),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(payment['status']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    payment['description'] ?? 'No description',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        payment['payment_method'] ?? 'Unknown method',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(payment['transaction_date']),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _paymentCacheBox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF081028),
      appBar: AppBar(
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF081028),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          try {
          await _checkForUpdates();
        } catch (e) {
          // Error handling is already done in _checkForUpdates
        }
      },
        color: Colors.blue,
        displacement: 40, // How far down the indicator appears
        strokeWidth: 2.5, // Thickness of the refresh indicator
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            : _errorOccurred
                ? _buildErrorState()
                : _payments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentList(),
      ),
    );
  }
}