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
      body: mapbox.MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: initialCameraOptions,
        styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
        onMapCreated: (controller) {
          mapboxMap = controller;
          _getCurrentLocation();
        },
      ),
    );
  }
}
