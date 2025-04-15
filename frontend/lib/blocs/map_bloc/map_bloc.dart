import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';

import 'map_event.dart';
import 'map_state.dart';

/// Bloc that manages all map-related events and state using Mapbox
class MapBloc extends Bloc<MapEvent, MapState> {
  late mapbox.PointAnnotationManager? _annotationManager;

  MapBloc() : super(MapState()) {
    // Request runtime location permission from the user
    on<RequestLocationPermission>((event, emit) async {
      await Permission.locationWhenInUse.request();
    });

    // Initialize map and annotations
    on<InitializeMap>((event, emit) async {
      emit(state.copyWith(mapController: event.mapController));
      _annotationManager = await state.mapController?.annotations.createPointAnnotationManager();
      add(GetCurrentLocation());
    });

    // Center map on the user's current location
    on<GetCurrentLocation>((event, emit) async {
      final position = await geolocator.Geolocator.getCurrentPosition();
      final point = mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude));

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );

      // Add the current location as a GeoJSON source for further use (optional layers)
      await state.mapController?.style.addSource(
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

      // Optional: Add circle layer to show user visually (can be uncommented)
      /*
      await state.mapController?.style.addLayer(
        mapbox.CircleLayer(
          id: 'user-location-layer',
          sourceId: 'user-location-source',
          circleColor: 4281558371,
          circleRadius: 8,
          circleStrokeColor: 0,
          circleStrokeWidth: 2,
        ),
      );
      */
    });

    // Increase map zoom level
    on<ZoomIn>((event, emit) async {
      final currentZoom = await state.mapController?.getCameraState();
      final newZoom = (currentZoom?.zoom ?? state.zoomLevel) + 1;

      state.mapController?.flyTo(
        mapbox.CameraOptions(zoom: newZoom),
        mapbox.MapAnimationOptions(duration: 500),
      );
      emit(state.copyWith(zoomLevel: newZoom));
    });

    // Decrease map zoom level
    on<ZoomOut>((event, emit) async {
      final currentZoom = await state.mapController?.getCameraState();
      final newZoom = (currentZoom?.zoom ?? state.zoomLevel) - 1;

      state.mapController?.flyTo(
        mapbox.CameraOptions(zoom: newZoom),
        mapbox.MapAnimationOptions(duration: 500),
      );
      emit(state.copyWith(zoomLevel: newZoom));
    });

    // Center camera to specific coordinates
    on<FlyTo>((event, emit) async {
      final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    });

    // Add a pin/marker to the map at given coordinates
    on<AddMarker>((event, emit) async {
      final map = state.mapController;
      if (map == null) return;

      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();

      final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));

      await _annotationManager?.deleteAll(); // Remove previous marker(s)

      await _annotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.5,
          image: imageData,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ),
      );
    });

    // Clear all markers from the map
    on<DeleteMarker>((event, emit) async {
      await _annotationManager?.deleteAll();
    });
  }
}