import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppController.init(); // memuat akun, permohonan, chat, sesi login
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
      home: const SplashScreen(),
    );
  }
}
