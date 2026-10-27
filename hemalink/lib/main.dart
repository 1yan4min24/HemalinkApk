import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppController.init(); // memulihkan sesi login & memuat data dari server
  runApp(const HemaLinkApp());
}

class HemaLinkApp extends StatelessWidget {
  const HemaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HemaLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: AppController.navigatorKey,
      scaffoldMessengerKey: AppController.messengerKey,
      home: const SplashScreen(),
    );
  }
}
