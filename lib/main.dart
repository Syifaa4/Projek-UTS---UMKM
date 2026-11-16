import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'ui/auth/login_page.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_controller.dart';
import 'ui/widgets/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final tema = ThemeController();
  await tema.muat();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: tema)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'DAGIRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.terang,
      darkTheme: AppTheme.gelap,
      themeMode: mode,
      // Latar dipasang sekali di sini, jadi login dan semua layar ikut
      builder: (context, child) => GlassBackground(child: child!),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snap.data == null ? const LoginPage() : const AppShell();
        },
      ),
    );
  }
}