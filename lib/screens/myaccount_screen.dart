import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../providers/myaccount_provider.dart';
import '../../models/profile_model.dart';

class MyAccountScreen extends ConsumerStatefulWidget {
  final ProfileModel profileData;
  const MyAccountScreen({super.key, required this.profileData});

  @override
  ConsumerState<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends ConsumerState<MyAccountScreen> {
  late ProfileModel profile;

  @override
void initState() {
  super.initState();
  profile = widget.profileData;
  Future.microtask(() {
    ref.read(myAccountProvider.notifier).load(profile);
  });
}


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myAccountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _showEditProfileDialog),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF57C3FF)))
          : RefreshIndicator(
              onRefresh: () async => await ref.read(myAccountProvider.notifier).refreshProfile(),
              color: const Color(0xFF57C3FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(state.profile!),
                    const SizedBox(height: 24),
                    _buildInfoSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      items: [
                        _buildInfoItem('Name', state.profile!.name),
                        _buildInfoItem('Email', state.profile!.email),
                        _buildInfoItem('Phone', state.profile!.phone),
                        _buildInfoItem('Member Since', _formatDate(state.profile!.joiningDate)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Membership',
                      icon: Icons.card_membership,
                      items: [
                        _buildInfoItem('Plan', state.profile!.membershipPlanId?.toString() ?? 'Not specified'),
                        _buildInfoItem('Status', state.profile!.feeStatus ?? 'Unknown'),
                        _buildInfoItem('Amount Due', '₹${state.profile!.amountDue?.toStringAsFixed(2) ?? '0.00'}'),
                        _buildInfoItem('Due Date', _formatDate(state.profile!.feeDueDate)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Emergency Contact',
                      icon: Icons.emergency,
                      items: [
                        _buildInfoItem('Name', state.profile!.emergencyContact ?? 'Not specified'),
                        _buildInfoItem('Phone', state.profile!.emergencyPhone ?? 'Not specified'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Health Metrics',
                      icon: Icons.monitor_heart,
                      items: [
                        _buildInfoItem('Height', state.profile!.height?.toString() ?? 'Not specified'),
                        _buildInfoItem('Target Weight', state.profile!.targetWeight?.toString() ?? 'Not specified'),
                        _buildInfoItem('Blood Group', state.profile!.bloodGroup ?? 'Not specified'),
                        _buildInfoItem('Date Of Birth', state.profile!.dob ?? 'Not specified'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit contact Information'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF57C3FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildHeaderCard(ProfileModel profile) {
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
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
            backgroundImage: profile.profileUrl != null
                ? NetworkImage(profile.profileUrl!)
                : const AssetImage('assets/images/profile.png') as ImageProvider,
            child: profile.profileUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.white54)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: TextStyle(color: const Color(0xFFAEB9E1).withOpacity(0.8), fontSize: 16),
        ),
      ],
    ),
  );
}


  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0B1739), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0064F4)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: items)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Not specified';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return 'Invalid date';
    }
  }

  void _showEditProfileDialog() {
    ref.read(myAccountProvider.notifier).showEditDialog(context);
  }
}
