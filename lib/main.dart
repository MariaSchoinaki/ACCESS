import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const ACCESS_TOKEN = String.fromEnvironment("token");


  MapboxOptions.setAccessToken(ACCESS_TOKEN);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}