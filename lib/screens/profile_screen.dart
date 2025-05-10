// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
//import '../../providers/token_provider.dart';
import 'login_screen.dart';
import 'myaccount_screen.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../providers/logout_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final String customerName;
  const ProfileScreen({super.key, required this.customerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
       
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF57C3FF)))
          : profileState.error != null
              ? Center(child: Text(profileState.error!, style: const TextStyle(color: Colors.red)))
              : profileState.profile == null
            ? const Center(
                child: Text(
                  'No profile data found.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : RefreshIndicator(
                  color:  Colors.white,
                  backgroundColor: const Color(0xFF0B1739),
                  onRefresh: () => controller.refreshProfile(),
                  child: _buildProfileContent(context, profileState.profile!, ref),
                ),
    );
  }

  Widget _buildProfileContent(BuildContext context, profile, WidgetRef ref) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: Column(
      children: [
        const SizedBox(height: 40),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1A3A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF57C3FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF57C3FF).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
  radius: 50,
  backgroundColor: const Color(0xFF0E1A3A),
  backgroundImage: profile.profileUrl != null && profile.profileUrl!.isNotEmpty
    ? NetworkImage(profile.profileUrl!)
    : null,
child: profile.profileUrl == null || profile.profileUrl!.isEmpty
    ? const Icon(Icons.person, size: 50, color: Colors.white70)
    : null,

),

              ),
              const SizedBox(height: 20),
              Text(
                profile.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                profile.email,
                style: const TextStyle(color: Color(0xFFAEB9E1), fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildProfileOption(
          icon: Icons.person,
          title: 'My Account',
          subtitle: 'View and edit personal details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyAccountScreen(profileData: profile),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildProfileOption(
          icon: Icons.lock,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => _showChangePasswordDialog(context),
        ),
        const SizedBox(height: 16),
        _buildProfileOption(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          isDestructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 40),
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
    final accentColor = isDestructive ? const Color(0xFFFF6B6B) : const Color(0xFF57C3FF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1A3A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2A5A).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.1),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isDestructive ? accentColor : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101B3C),
            title: const Text('Change Password', style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Old Password'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter old password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                        value == null || value.length < 6 ? 'Password too short' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                        value != newPasswordController.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isSubmitting = true);

                        try {
                          final response = await ApiService().authenticatedPost(
                            'auth/reset-password',
                            body: {
                              'old_password': oldPasswordController.text,
                              'new_password': newPasswordController.text,
                            },
                          );

                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: Colors.green,
                            ));
                          } else {
                            final errorMsg = jsonDecode(response.body)['message'] ?? 'Failed to update password';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red,
                            ));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ));
                        } finally {
                          setState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Change', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(logoutProvider).logoutAll();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
