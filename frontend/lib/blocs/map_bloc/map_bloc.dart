import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import '../../models/mapbox_feature.dart';

part 'map_event.dart';
part 'map_state.dart';

/// Bloc that manages all map-related events and state using Mapbox
class MapBloc extends Bloc<MapEvent, MapState> {
  late mapbox.PointAnnotationManager? _annotationManager;
  late mapbox.PointAnnotationManager? _categoryAnnotationManager;

  MapBloc() : super(MapState()) {
    // Request runtime location permission from the user
    on<RequestLocationPermission>((event, emit) async {
      await Permission.locationWhenInUse.request();
    });

    // Initialize map and annotations
    on<InitializeMap>((event, emit) async {
      emit(state.copyWith(mapController: event.mapController));
      _annotationManager = await state.mapController?.annotations.createPointAnnotationManager();
      _categoryAnnotationManager = await state.mapController?.annotations.createPointAnnotationManager(); // Create a separate manager for category markers
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

    // Add a pin/marker to the map at given coordinates (e.g., long tap)
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

    // Clear all markers from the map (long tap markers)
    on<DeleteMarker>((event, emit) async {
      await _annotationManager?.deleteAll();
    });

    // Add multiple markers for category search results
    on<AddCategoryMarkers>((event, emit) async {
      final map = state.mapController;
      if (map == null) return;

      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();
      final Set<mapbox.PointAnnotation> newAnnotations = {};

      double? minLat, maxLat, minLng, maxLng;

      for (final feature in event.features) {
        final point = mapbox.Point(coordinates: mapbox.Position(feature.longitude, feature.latitude));
        final annotation = await _categoryAnnotationManager?.create(
          mapbox.PointAnnotationOptions(
            geometry: point,
            iconSize: 0.4,
            image: imageData,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
            textField: feature.name,
          ),
        );
        if (annotation != null) {
          newAnnotations.add(annotation);

          final lat = feature.latitude;
          final lng = feature.longitude;
          minLat = minLat == null ? lat : min(minLat, lat);
          maxLat = maxLat == null ? lat : max(maxLat, lat);
          minLng = minLng == null ? lng : min(minLng, lng);
          maxLng = maxLng == null ? lng : max(maxLng, lng);
        }
      }

      emit(state.copyWith(categoryAnnotations: newAnnotations));

      if (event.shouldZoomToBounds && minLat != null && maxLat != null && minLng != null && maxLng != null && map != null) {
        final southwest = mapbox.Point(coordinates: mapbox.Position(minLng, minLat));
        final northeast = mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat));

        final bounds = mapbox.CoordinateBounds(southwest: southwest, northeast: northeast, infiniteBounds: true);

        final cameraOptions = await map.cameraForCoordinateBounds(
          bounds,
          mapbox.MbxEdgeInsets(
            top: 50.0,
            left: 50.0,
            bottom: 50.0,
            right: 50.0,
          ),
          0.0,
          0.0,
          null,
          null,
        );

        if (cameraOptions != null) {
          map.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 1000));
        }
      }
    });

    // Clears all category markers from the map
    on<ClearCategoryMarkers>((event, emit) async {
      await _categoryAnnotationManager?.deleteAll();
      emit(state.copyWith(categoryAnnotations: {}));
    });
  }


}