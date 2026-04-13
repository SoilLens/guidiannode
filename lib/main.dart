import 'package:flutter/material.dart';

import 'core/services/app_preferences.dart';
import 'core/theme/theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/emergency/services/supabase_realtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.ensureInitialized();
  await SupabaseRealtimeService.instance.initialize();
  runApp(const GuardianNodeApp());
}

class GuardianNodeApp extends StatelessWidget {
  const GuardianNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuardianNode',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
