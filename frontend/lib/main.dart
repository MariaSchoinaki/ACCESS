import 'package:access/screens/myaccount/log%20in/log_in_page.dart';
import 'package:access/screens/myaccount/myaccount_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Entry point of the Flutter application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Securely retrieves the Mapbox access token via --dart-define
  const ACCESS_TOKEN = String.fromEnvironment("token");

  // Validate token and initialize Mapbox
  if (ACCESS_TOKEN.isEmpty) {
    throw Exception('Missing Mapbox access token. Provide it with --dart-define=token=YOUR_TOKEN_HERE');
  }

  MapboxOptions.setAccessToken(ACCESS_TOKEN);

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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
      routes: {
        //'/signup': (context) => SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/myaccount': (context) => const MyAccountScreen(),

      },
    );
  }
}
