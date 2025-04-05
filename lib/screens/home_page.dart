import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  mapbox.MapboxMap? mapboxMap;

  final mapbox.CameraOptions initialCameraOptions = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(23.7325, 37.9908)),
      zoom: 14.0,
      bearing: 0,
      pitch: 0
  );

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> _getCurrentLocation() async {
    final position = await geolocator.Geolocator.getCurrentPosition();

    final point = mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude));
    developer.log(
      'Τοποθεσία',
      name: 'location',
      error: 'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
    );

    mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: point,
        zoom: 16.0,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );

    await mapboxMap?.style.addSource(
      mapbox.GeoJsonSource(
        id: 'user-location-source',
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [position.longitude, position.latitude],
              },
            }
          ],
        }),
      ),
    );

    await mapboxMap?.style.addLayer(
      mapbox.CircleLayer(
        id: 'user-location-layer',
        sourceId: 'user-location-source',
        circleColor: 4281558371,
        circleRadius: 8,
        circleStrokeColor: 0,
        circleStrokeWidth: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Search bar
          Container(
            color: Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Αναζήτηση...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onSubmitted: (value) {
                  // TODO: search automation with mapbox geolocation api
                },
              ),
            ),
          ),

          Expanded(
            child: mapbox.MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: initialCameraOptions,
              styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
              onMapCreated: (controller) {
                mapboxMap = controller;
                _getCurrentLocation();
              },
            ),
          ),

          // Bottom Tab
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "bottom tab",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
