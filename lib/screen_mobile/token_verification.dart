import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'login_screen.dart';
//import 'main_screen.dart';

class TokenVerificationWrapper extends StatefulWidget {
  final String baseUrl;
  final Widget child;

  const TokenVerificationWrapper({
    Key? key,
    required this.baseUrl,
    required this.child,
  }) : super(key: key);

  @override
  State<TokenVerificationWrapper> createState() => _TokenVerificationWrapperState();
}

class _TokenVerificationWrapperState extends State<TokenVerificationWrapper> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isValidToken = false;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final authBox = Hive.box('auth');
      final accessToken = authBox.get('access_token');
      final refreshToken = authBox.get('refresh_token');

      // No tokens found → Redirect to login
      if (accessToken == null || refreshToken == null) {
        _redirectToLogin();
        return;
      }

      // Validate token with backend
      final response = await _apiService.authenticatedGet('auth/verify-token');
      
      if (response.statusCode == 200) {
        // Token valid → Proceed to MainScreen
        setState(() {
          _isValidToken = true;
          _isLoading = false;
        });
      } else {
        // Token invalid → Clear storage and redirect
        await authBox.clear();
        _redirectToLogin();
      }
    } catch (e) {
      // Network error → Redirect with message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        _redirectToLogin();
      }
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }
    return _isValidToken ? widget.child : SizedBox.shrink();
  }
}