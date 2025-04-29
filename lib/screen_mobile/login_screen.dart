import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_screen.dart';
import 'api_service.dart';
import 'dart:async';
import 'dart:developer' as developer; // For debug logging
import 'dart:io';
import '../services/hive_service.dart'; //Added by sreekesh

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ApiService _apiService = ApiService();
  Box? _authBox;
  // Configuration
  //static const bool isProduction = false;
  //static const String localBaseUrl = 'http://192.168.1.47:5000';
  // static const String productionBaseUrl = 'https://your-production-api.com';
  //String get baseUrl => isProduction ? productionBaseUrl : localBaseUrl;

  @override
  void initState() {
    super.initState();
    _initializeHiveAndNavigate();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateLoginResponse(Map<String, dynamic> response) {
    final requiredFields = [
      'access_token',
      'refresh_token',
      'customer_id',
      'client_id',
      'customer_name',
    ];

    for (final field in requiredFields) {
      if (response[field] == null) {
        throw Exception('Missing required field: $field');
      }
    }
  }

  Future<void> _initializeHiveAndNavigate() async {
    await HiveService.openBox('auth');
    _authBox = Hive.box('auth'); // Save it once
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      developer.log(
        'Attempting login to ${_apiService.baseUrl}/auth/login',
        name: 'LoginScreen',
      );
      developer.log(
        'Request payload: ${{
          'email': _emailController.text.trim(),
          'password': '••••••', // Don't log actual password
        }}',
        name: 'LoginScreen',
      );

      final response = await _apiService
          .authenticatedPost(
            'auth/login',
            body: {
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 10));

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'LoginScreen',
      );
      developer.log(
        'Response headers: ${response.headers}',
        name: 'LoginScreen',
      );
      developer.log('Response body: ${response.body}', name: 'LoginScreen');

      final responseData = jsonDecode(response.body);
      _validateLoginResponse(responseData);

      await _storeAuthData(
        responseData['access_token'],
        responseData['refresh_token'],
        responseData['customer_id'],
        responseData['client_id'],
        responseData['customer_name'],
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => TokenVerificationWrapper(
                baseUrl:
                    _apiService
                        .baseUrl, // Changed from 'baseUrl' to '_apiService.baseUrl'
                child: MainScreen(customerName: responseData['customer_name']),
              ),
        ),
      );
    } on SocketException catch (e) {
      developer.log(
        'SocketException: ${e.toString()}',
        name: 'LoginScreen',
        error: e,
      );
      _showError(
        'Network unreachable. Please check:\n'
        '• Server running at ${_apiService.baseUrl}\n'
        '• Your internet connection',
      );
    } on TimeoutException catch (e) {
      developer.log(
        'TimeoutException: ${e.toString()}',
        name: 'LoginScreen',
        error: e,
      );
      _showError('Connection timeout. Server may be busy');
    } on http.ClientException catch (e) {
      developer.log(
        'ClientException: ${e.toString()}',
        name: 'LoginScreen',
        error: e,
      );
      _showError('Network error: ${e.message}');
    } on ApiException catch (e) {
      developer.log(
        'ApiException: ${e.statusCode} - ${e.message}',
        name: 'LoginScreen',
        error: e,
      );
      _showError(e.message);
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error: ${e.toString()}',
        name: 'LoginScreen',
        error: e,
        stackTrace: stackTrace,
      );
      _showError('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _storeAuthData(
    String token,
    String refreshToken,
    int customerId,
    int clientId,
    String customerName,
  ) async {
    await _authBox?.putAll({
      'access_token': token,
      'refresh_token': refreshToken,
      'customer_id': customerId,
      'client_id': clientId,
      'customer_name': customerName,
      'isLoggedIn': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/bird.png',
                            width: 80,
                            height: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gym Management',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Login in to continue',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordModal(context),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordModal(BuildContext context) {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool _showOtpField = false;
    bool _showNewPasswordFields = false;
    bool _isLoading = false;

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
                      Text(
                        'Reset Password',
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
                  if (!_showOtpField && !_showNewPasswordFields)
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  if (_showOtpField && !_showNewPasswordFields)
                    TextFormField(
                      controller: otpController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.lock_clock,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (_showNewPasswordFields) ...[
                    TextFormField(
                      controller: otpController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.lock_clock,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                if (!_showOtpField && !_showNewPasswordFields) {
                                  if (emailController.text.isEmpty) {
                                    _showError('Please enter your email');
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    final response = await http.post(
                                      Uri.parse(
                                        '${_apiService.baseUrl}/auth/forgot-password',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'email': emailController.text,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        _showOtpField = true;
                                        _isLoading = false;
                                      });
                                    } else {
                                      _showError('Failed to send OTP');
                                      setState(() => _isLoading = false);
                                    }
                                  } catch (e) {
                                    _showError('Error: ${e.toString()}');
                                    setState(() => _isLoading = false);
                                  }
                                } else if (_showOtpField &&
                                    !_showNewPasswordFields) {
                                  if (otpController.text.isEmpty) {
                                    _showError('Please enter OTP');
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    final response = await http.post(
                                      Uri.parse(
                                        '${_apiService.baseUrl}/auth/verify-otp',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'email': emailController.text,
                                        'otp': otpController.text,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        _showNewPasswordFields = true;
                                        _isLoading = false;
                                      });
                                    } else {
                                      _showError('Invalid OTP');
                                      setState(() => _isLoading = false);
                                    }
                                  } catch (e) {
                                    _showError('Error: $e');
                                    setState(() => _isLoading = false);
                                  }
                                } else if (_showNewPasswordFields) {
                                  if (newPasswordController.text.isEmpty) {
                                    _showError('Please enter new password');
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    final response = await http.post(
                                      Uri.parse(
                                        '${_apiService.baseUrl}/auth/reset-password',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'email': emailController.text,
                                        'otp': otpController.text,
                                        'new_password':
                                            newPasswordController.text,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password reset successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      _showError('Failed to reset password');
                                      setState(() => _isLoading = false);
                                    }
                                  } catch (e) {
                                    _showError('Error: $e');
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                !_showOtpField && !_showNewPasswordFields
                                    ? 'SEND OTP'
                                    : _showOtpField && !_showNewPasswordFields
                                    ? 'VERIFY OTP'
                                    : 'RESET PASSWORD',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
}

class TokenVerificationWrapper extends StatefulWidget {
  final String baseUrl;
  final Widget child;

  const TokenVerificationWrapper({
    super.key,
    required this.baseUrl,
    required this.child,
  });

  @override
  State<TokenVerificationWrapper> createState() =>
      _TokenVerificationWrapperState();
}

class _TokenVerificationWrapperState extends State<TokenVerificationWrapper> {
  bool _isVerified = false;
  bool _isLoading = true;
  final _apiService = ApiService();
  Box? _authBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
    _verifyToken();
  }

  Future<void> _initializeHive() async {
    await HiveService.openBox('auth');
    _authBox = Hive.box('auth'); // Save it once
  }

  Future<void> _verifyToken() async {
    final token = _authBox?.get('access_token');
    final refreshToken = _authBox?.get('refresh_token');

    if (token == null || refreshToken == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await _apiService.authenticatedGet('auth/verify-token');

      if (response.statusCode == 200) {
        _handleSuccess();
      } else {
        _handleFailure();
      }
    } catch (e) {
      _showErrorAndRedirect('Session expired. Please login again.');
    }
  }

  void _handleSuccess() {
    if (mounted) {
      setState(() {
        _isVerified = true;
        _isLoading = false;
      });
    }
  }

  void _showErrorAndRedirect(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
      _redirectToLogin();
    }
  }

  void _handleFailure() async {
    await _authBox?.clear(); // Clear all auth data, not just access_token
    _redirectToLogin();
  }

  void _redirectToLogin() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    return _isVerified ? widget.child : const SizedBox.shrink();
  }
}
