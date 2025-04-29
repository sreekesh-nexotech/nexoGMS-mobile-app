import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; 

class MyAccountScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const MyAccountScreen({super.key, required this.profileData});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  late Map<String, dynamic> _profileData;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _profileData = Map<String, dynamic>.from(widget.profileData);
  }

  void _showEditProfileDialog() {
   // final nameController = TextEditingController(text: _profileData['name']);
    final phoneController = TextEditingController(text: _profileData['phone']);
    final emgContactController = TextEditingController(text: _profileData['emg_contact'] ?? '');
    final emgContactNoController = TextEditingController(text: _profileData['emg_contact_no'] ?? '');
    //final profileUrlController = TextEditingController(text: _profileData['profile_url'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit contact information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
               // _buildTextField('Name', nameController),
                _buildTextField('Phone', phoneController),
                _buildTextField('Emergency Contact', emgContactController),
                _buildTextField('Emergency Phone', emgContactNoController),
               // _buildTextField('Profile URL', profileUrlController),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateProfile(
                        //name: nameController.text,
                        phone: phoneController.text,
                        emgContact: emgContactController.text,
                        emgContactNo: emgContactNoController.text,
                        //profileUrl: profileUrlController.text,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF57C3FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SAVE CHANGES',
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

  Widget _buildTextField(String label, TextEditingController controller) {
  bool isPhoneField = label.contains('Phone');
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: isPhoneField ? TextInputType.phone : TextInputType.text,
      maxLength: isPhoneField ? 10 : null,
      inputFormatters: isPhoneField 
          ? [FilteringTextInputFormatter.digitsOnly] 
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        counterText: '', // Hide counter for phone fields
        hintText: isPhoneField ? 'Enter 10-digit number' : null,
      ),
    ),
  );
}

 Future<void> _refreshProfileData() async {
  setState(() => _isRefreshing = true);
  try {
    final response = await _apiService.authenticatedGet('customer/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _profileData = {
          ..._profileData,  // Keep any existing data not in the response
          ...data,         // Update with new data
          'phone': data['phone'] ?? _profileData['phone'],
          'emg_contact': data['emg_contact'] ?? _profileData['emg_contact'],
          'emg_contact_no': data['emg_contact_no'] ?? _profileData['emg_contact_no'],
        };
      });
    } else {
      throw ApiException('Failed to load profile', response.statusCode);
    }
  } on ApiException catch (e) {
    if (mounted) {
      _showErrorSnackbar(e.message);
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackbar('Error refreshing profile: ${e.toString()}');
    }
    debugPrint('Refresh profile error: $e');
  } finally {
    setState(() => _isRefreshing = false);
  }
}

  Future<void> _updateProfile({
  required String phone,
  required String emgContact,
  required String emgContactNo,
}) async {
  // Validate phone numbers before API call
  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
    _showErrorSnackbar('Primary phone must be exactly 10 digits');
    return;
  }

  if (emgContactNo.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(emgContactNo)) {
    _showErrorSnackbar('Emergency phone must be exactly 10 digits');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await _apiService.authenticatedPut(
      'customer/profile',
      body: {
        'phone': phone,
        'emg_contact': emgContact,  // Make sure this matches your backend
        'emg_contact_no': emgContactNo,  // And this too
        'client_last_updated': _profileData['last_updated_on'],
      },
    );

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body);
      setState(() {
        _profileData = {
          ..._profileData,  // Keep existing data
          'phone': phone,
          'emg_contact': emgContact,
          'emg_contact_no': emgContactNo,
          'last_updated_on': updatedData['last_updated_on'] ?? _profileData['last_updated_on'],
        };
      });
      if (mounted) {
        _showSuccessSnackbar('Contact information updated successfully');
      }
    } else {
      final error = jsonDecode(response.body);
      _showErrorSnackbar(error['error'] ?? 'Update failed (${response.statusCode})');
    }
  } catch (e) {
    _showErrorSnackbar('Error: ${e.toString()}');
    debugPrint('Update profile error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ),
  );
}

void _showSuccessSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF081028), // Keep original background
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF081028), // Keep original appbar color
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF57C3FF), // Lighter blue for loading
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isRefreshing = true);
                await _refreshProfileData();
                setState(() => _isRefreshing = false);
              },
              color: Color(0xFF57C3FF),
              child: _isRefreshing 
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Header Card
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Color(0xFF0E1A3A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF57C3FF),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF57C3FF).withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Color(0xFF0E1A3A),
                                    backgroundImage: _profileData['profile_url'] != null
                                        ? NetworkImage(_profileData['profile_url'])
                                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                                    child: _profileData['profile_url'] == null
                                        ? Icon(Icons.person, size: 50, color: Colors.white54)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _profileData['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profileData['email'],
                                  style: TextStyle(
                                    color: Color(0xFFAEB9E1).withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Information Sections
                          _buildInfoSection(
                            title: 'Personal Information',
                            icon: Icons.person_outline,
                            items: [
                              _buildInfoItem('Name', _profileData['name']),
                              _buildInfoItem('Email', _profileData['email']),
                              _buildInfoItem('Phone', _profileData['phone']),
                              _buildInfoItem('Member Since', _formatDate(_profileData['joining_date'])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            title: 'Membership',
                            icon: Icons.card_membership,
                            items: [
                              _buildInfoItem('Plan', _profileData['membership_plan_id']?.toString() ?? 'Not specified'),
                              _buildInfoItem('Status', _profileData['fee_status'] ?? 'Unknown'),
                              _buildInfoItem('Amount Due', '\$${_profileData['amount_due']?.toStringAsFixed(2) ?? '0.00'}'),
                              _buildInfoItem('Due Date', _formatDate(_profileData['fee_due_date'])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            title: 'Emergency Contact',
                            icon: Icons.emergency,
                            items: [
                              _buildInfoItem('Name', _profileData['emg_contact'] ?? 'Not specified'),
                              _buildInfoItem('Phone', _profileData['emg_contact_no'] ?? 'Not specified'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            title: 'Health Metrics',
                            icon: Icons.emergency,
                            items: [
                              _buildInfoItem('Height', _profileData['height']?.toString() ?? 'Not specified'),
                              _buildInfoItem('Target Weight', _profileData['target_weight']?.toString() ?? 'Not specified'),
                              _buildInfoItem('Blood Group', _profileData['blood_group'] ?? 'Not specified'),
                              _buildInfoItem('Date Of Birth', _profileData['dob'] ?? 'Not specified'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('Edit contact Information'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF57C3FF),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
    );
    
  }


  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF0064F4)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    String displayValue;
  
  if (value == null) {
    displayValue = 'Not specified';
  } else if (value is num) {
    // Handle numbers (int/double)
    displayValue = value.toString();
  } else if (value is String) {
    // Handle strings
    displayValue = value;
  } else {
    // Handle other types
    displayValue = value.toString();
  }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not specified';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
