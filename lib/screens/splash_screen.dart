import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../screens/token_verification.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    final authBox = await Hive.openBox('auth');
    final accessToken = authBox.get('access_token');
    final refreshToken = authBox.get('refresh_token');
    final customerName = authBox.get('customer_name') ?? 'User';
    print('✅ access_token: $accessToken');
print('✅ refresh_token: $refreshToken');
print('✅ customer_name: $customerName');


    if (accessToken != null && refreshToken != null) {
      // Use token verification wrapper to check with backend
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TokenVerificationWrapper(
            child: MainScreen(customerName: customerName),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/nexogms_logo.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  }