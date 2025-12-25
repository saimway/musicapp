import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';
import 'controllers/music_controller.dart';
import 'main_overlay.dart';

void main() {
  runApp(const MyApp());
}

// NOTE: The overlay entry point is defined in main_overlay.dart
// allowing it to run in a separate isolate if needed, though
// flutter_overlay_window often uses a specific entry point.

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller permanently
    Get.put(MusicController());

    return GetMaterialApp(
      title: 'Island Vibes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          background: const Color(0xFF121212),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
