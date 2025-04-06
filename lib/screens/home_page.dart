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
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Αναζήτηση...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onSubmitted: (value) {
                      // TODO: search
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
            ],
          ),

          // ZOOM BUTTONS
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "location",
                  mini: true,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    final currentZoom = await mapboxMap?.getCameraState();
                    mapboxMap?.flyTo(
                      mapbox.CameraOptions(zoom: (currentZoom?.zoom ?? 14.0) + 1),
                      mapbox.MapAnimationOptions(duration: 500),
                    );
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () async {
                    final currentZoom = await mapboxMap?.getCameraState();
                    mapboxMap?.flyTo(
                      mapbox.CameraOptions(zoom: (currentZoom?.zoom ?? 14.0) - 1),
                      mapbox.MapAnimationOptions(duration: 500),
                    );
                  },
                ),
              ],
            ),
          ),

          // Κάτω Μπάρα Πλοήγησης
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.home, color: Colors.black),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person, color: Colors.black),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}