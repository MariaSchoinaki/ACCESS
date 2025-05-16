// Flutter constant for checking if platform is Web
import 'package:access/web_screens/home_web_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



// Mapbox plugin (only works on Android/iOS, not supported on Web)
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Main entry point of the application
Future<void> main() async {
  // Ensure Flutter engine is initialized before any plugin usage
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms (Android, iOS, Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run different app depending on platform
  runApp(const WebApp());
}


//
// ==============================================
// WEB VERSION (Browser)
// ==============================================
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic scaffold for the web version
    return MaterialApp(
      title: 'Accessible City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      initialRoute: '/webhome',
      routes: {
        '/webhome': (context) => const HomeWebScreen(),
      },
    );
  }
}
