import 'package:flutter/material.dart';
//import 'screens/login_screen.dart';
//import 'screens_web/home_screen.dart';
import 'screen_mobile/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Hive.openBox('auth');       // For tokens (e.g., access_token, refresh_token)
  await Hive.openBox('user_data');  // For user profile (name, email, etc.)
  await Hive.openBox('app_cache');  // For general app data (optional)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexotech Gym App',
      
      theme:ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), //LoginScreen(),//
    );
  }
}

