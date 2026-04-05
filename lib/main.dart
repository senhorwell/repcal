import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/calibration_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const PullUpCaloriesApp());
}

class PullUpCaloriesApp extends StatelessWidget {
  const PullUpCaloriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pull-up Calories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: CalibrationScreen(cameras: cameras),
    );
  }
}
