import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'profile_service.dart';
import 'myaccount_screen.dart';
import 'dart:convert';
import 'Cache_Manager.dart';
import '../services/hive_service.dart'; //Added by sreekesh

class ProfileScreen extends StatefulWidget {
  final String customerName;

  const ProfileScreen({super.key, required this.customerName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isUpdating = false;
  late Box _authBox;
  // DateTime _lastApiCallTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initHiveAndFetchData();
  }

  Future<void> _initHiveAndFetchData() async {
    _authBox = await HiveService.openBox('authBox');
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData({bool forceRefresh = false}) async {
    //if (DateTime.now().difference(_lastApiCallTime) < Duration(seconds: 1)) {
    // return; // Skip if called recently
    // }
    //_lastApiCallTime = DateTime.now();

    if (mounted) setState(() => _isLoading = true);

    try {
      final profile = await ProfileService.getProfile(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _profileData = profile;
        });
        await _authBox.put('profile', profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        if (_profileData == null && _authBox.containsKey('profile')) {
          setState(() => _profileData = _authBox.get('profile'));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _isUpdatingPassword = false;
    bool _obscureOldPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Password',
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
                  _buildPasswordField(
                    controller: oldPasswordController,
                    label: 'Current Password',
                    obscureText: _obscureOldPassword,
                    toggleVisibility:
                        () => setState(
                          () => _obscureOldPassword = !_obscureOldPassword,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'New Password',
                    obscureText: _obscureNewPassword,
                    toggleVisibility:
                        () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isUpdatingPassword
                              ? null
                              : () async {
                                if (newPasswordController.text !=
                                    confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isUpdatingPassword = true);
                                try {
                                  final response = await _apiService
                                      .authenticatedPost(
                                        'auth/reset-password',
                                        body: {
                                          'old_password':
                                              oldPasswordController.text,
                                          'new_password':
                                              newPasswordController.text,
                                        },
                                      );

                                  if (response.statusCode == 200) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password updated successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    final error =
                                        jsonDecode(response.body)['error'];
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error ?? 'Failed to update password',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                } finally {
                                  setState(() => _isUpdatingPassword = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0064F4),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isUpdatingPassword
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'UPDATE PASSWORD',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

  Future<void> _handleProfileUpdate() async {
    if (_isLoading || _profileData == null) return;

    setState(() => _isUpdating = true);
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MyAccountScreen(
                profileData: Map<String, dynamic>.from(_profileData!),
              ),
        ),
      );

      if (result != null && mounted) {
        await _fetchProfileData(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await _apiService.logout();
      } finally {
        await CacheManager.clearAllCache();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF081028), // Keep original background
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF081028), // Keep original appbar color
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchProfileData(forceRefresh: true),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF57C3FF), // Lighter blue for loading
                ),
              )
              : Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Profile Header Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFF0E1A3A), // Darker blue container
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
                                    color: Color(
                                      0xFF57C3FF,
                                    ), // Lighter blue border
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
                                  backgroundImage:
                                      _profileData?['profile_url'] != null
                                          ? NetworkImage(
                                            _profileData!['profile_url'],
                                          )
                                          : const AssetImage(
                                                'assets/images/profile.png',
                                              )
                                              as ImageProvider,
                                  child:
                                      _profileData?['profile_url'] == null
                                          ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white54,
                                          )
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _profileData?['name'] ?? widget.customerName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _profileData?['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFAEB9E1).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Options Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                icon: Icons.person_outline,
                                title: 'My Account',
                                subtitle: 'Update your personal information',
                                onTap: _handleProfileUpdate,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileOption(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                subtitle: 'Set a new secure password',
                                onTap: _showChangePasswordDialog,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileOption(
                                icon: Icons.logout,
                                title: 'Logout',
                                subtitle: 'Sign out of your account',
                                isDestructive: true,
                                onTap: () => _logout(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  if (_isUpdating)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(
                              0xFF57C3FF,
                            ), // Lighter blue for loading
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final accentColor = isDestructive ? Color(0xFFFF6B6B) : Color(0xFF57C3FF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0E1A3A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF1A2A5A).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? accentColor : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
