import 'package:access/screens/login_screen.dart';
import 'package:access/screens/myaccount_screen.dart';
import 'package:access/screens/sign_up_screen.dart';
import 'package:access/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Entry point of the Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Securely retrieves the Mapbox access token via --dart-define
  const ACCESS_TOKEN = String.fromEnvironment("token");

  // Validate token and initialize Mapbox
  if (ACCESS_TOKEN.isEmpty) {
    throw Exception('Missing Mapbox access token. Provide it with --dart-define=token=YOUR_TOKEN_HERE');
  }

  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Launch the Flutter application
  runApp(const MyApp());
}

/// Root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Search App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: const HomePage(),
      routes: {
        '/signup': (context) => SignUpPage(),
        '/login': (context) => LoginScreen(),
        '/myaccount': (context) => const MyAccountScreen(),

      },
    );
  }
}
