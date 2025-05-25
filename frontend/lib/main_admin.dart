import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';


/// Main entry point of the application
Future<void> main() async {
  // Ensure Flutter engine is initialized before any plugin usage
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms (Android, iOS, Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run different app depending on platform
  runApp(const AdminApp());
}

//
// ==============================================
// ADMIN APPLICATION
// ==============================================
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Access Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const AdminAuthGate(),
      },
    );
  }
}