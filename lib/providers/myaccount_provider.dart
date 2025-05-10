import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';


final myAccountProvider = StateNotifierProvider<MyAccountNotifier, MyAccountState>(
  (ref) => MyAccountNotifier(),
);

class MyAccountState {
  final ProfileModel? profile;
  final bool isLoading;

  MyAccountState({this.profile, this.isLoading = false});

  MyAccountState copyWith({ProfileModel? profile, bool? isLoading}) {
    return MyAccountState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MyAccountNotifier extends StateNotifier<MyAccountState> {
  MyAccountNotifier() : super(MyAccountState());

  final ApiService _apiService = ApiService();

  void load(ProfileModel profile) {
    state = state.copyWith(profile: profile, isLoading: false);
  }

  Future<void> refreshProfile() async {
    try {
      state = state.copyWith(isLoading: true);
      final res = await _apiService.authenticatedGet('customer/profile');
      final data = ProfileModel.fromJson(jsonDecode(res.body));
      state = state.copyWith(profile: data, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void showEditDialog(BuildContext rootContext) {
  final phoneCtrl = TextEditingController(text: state.profile?.phone ?? '');
  final emgNameCtrl = TextEditingController(text: state.profile?.emergencyContact ?? '');
  final emgPhoneCtrl = TextEditingController(text: state.profile?.emergencyPhone ?? '');

  showModalBottomSheet(
    context: rootContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit contact information',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField('Phone Number', phoneCtrl, TextInputType.phone),
                _buildField('Emergency Contact Name', emgNameCtrl, TextInputType.name),
                _buildField('Emergency Phone Number', emgPhoneCtrl, TextInputType.phone),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateContact(
                        phoneCtrl.text,
                        emgNameCtrl.text,
                        emgPhoneCtrl.text,
                        ctx, // modal context
                        rootContext, // for showing SnackBar
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57C3FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

 Widget _buildField(String label, TextEditingController controller, TextInputType inputType) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: inputType,
      maxLength: inputType == TextInputType.phone ? 10 : null,
      inputFormatters: inputType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.singleLineFormatter],
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        counterText: '',
      ),
    ),
  );
}

 Future<void> _updateContact(
  String phone,
  String emgName,
  String emgPhone,
  BuildContext modalContext,
  BuildContext rootContext,
) async {
  Navigator.pop(modalContext); // Close the modal first
  await Future.delayed(const Duration(milliseconds: 200)); // Let modal animate out

  final trimmedPhone = phone.trim();
  final trimmedEmgPhone = emgPhone.trim();
  final trimmedEmgName = emgName.trim();

  // Validate phone (if not empty)
  if (trimmedPhone.isNotEmpty && (!RegExp(r'^\d{10}$').hasMatch(trimmedPhone))) {
    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text('Phone number must be exactly 10 digits'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Validate emergency phone (if not empty)
  if (trimmedEmgPhone.isNotEmpty && (!RegExp(r'^\d{10}$').hasMatch(trimmedEmgPhone))) {
    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text('Emergency phone number must be exactly 10 digits'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    await _apiService.authenticatedPut(
      'customer/profile',
      body: {
        'phone': trimmedPhone,
        'emg_contact': trimmedEmgName,
        'emg_contact_no': trimmedEmgPhone,
      },
    );

    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text('Contact information updated'),
        backgroundColor: Colors.green,
      ),
    );

    refreshProfile();
  } catch (e) {
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text('Update failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

}