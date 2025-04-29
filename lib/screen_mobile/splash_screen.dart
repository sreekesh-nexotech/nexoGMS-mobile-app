import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:async';
import 'main_screen.dart';
//import 'token_verification.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  final String baseUrl = 'http://192.168.1.47:5000'; 

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _controller.forward();
    
    // Navigate to LoginScreen after 2.5 seconds
    Timer(Duration(milliseconds: 2500), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final authBox = Hive.box('auth');
    final accessToken = authBox.get('access_token');
    final customerName = authBox.get('customer_name', defaultValue: 'User');

    if (accessToken != null) {
      // Token exists → Verify and go to MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TokenVerificationWrapper(
            baseUrl: baseUrl,
            child: MainScreen(customerName: customerName),
          ),
        ),
      );
    } else {
      // No token → Redirect to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with fade and scale animation
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Text with gradient and subtle shadow
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.blue,
                              Colors.white,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'Nexotech Solutions',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.blue.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Loading indicator
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                          minHeight: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}