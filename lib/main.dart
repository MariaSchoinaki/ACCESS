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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}


/**
 *
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const ACCESS_TOKEN = String.fromEnvironment("token");


  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  // Define options for your camera
  CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-98.0, 39.5)),
      zoom: 2,
      bearing: 0,
      pitch: 0);

  // Run your application, passing your CameraOptions to the MapWidget
  runApp(MaterialApp(home: MapWidget(
    cameraOptions: camera,
      styleUri: MapboxStyles.SATELLITE_STREETS
  )));
}
*/