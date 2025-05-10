import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/cache_utils.dart';

void main() async {
  // Initialize Hive if you're using it
  
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth');
  await Hive.initFlutter();
  await CacheManager.initializeAll(); // open all boxes safely

  //await Hive.deleteBoxFromDisk('workoutData');
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexoGMS',
      theme: ThemeData.dark(), // or your custom theme
      home: const SplashScreen(),
    );
  }
}