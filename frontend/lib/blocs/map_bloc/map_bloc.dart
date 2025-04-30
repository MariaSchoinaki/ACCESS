import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import '../../models/mapbox_feature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'map_bloc.dart';

part 'map_event.dart';
part 'map_state.dart';

/// Manages map-related state and logic using Mapbox Maps SDK and Flutter BLoC.
///
/// Handles events such as map initialization, user location requests, zooming,
/// adding/removing markers, tracking user movement, and displaying features.
class MapBloc extends Bloc<MapEvent, MapState> {
  /// Manages single point annotations (like user-added markers).
  late mapbox.PointAnnotationManager? _annotationManager;

  /// Manages point annotations for categories of features.
  late mapbox.PointAnnotationManager? _categoryAnnotationManager;

  /// Subscription to the device's location updates stream.
  StreamSubscription<geolocator.Position>? _positionSubscription;

  /// Platform interface for accessing geolocation services.
  final geolocator.GeolocatorPlatform _geolocator = geolocator
      .GeolocatorPlatform.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initializes the MapBloc with the initial state and registers event handlers.
  MapBloc() : super(MapState.initial()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<InitializeMap>(_onInitializeMap);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<FlyTo>(_onFlyTo);
    on<AddMarker>(_onAddMarker);
    on<DeleteMarker>(_onDeleteMarker);
    on<AddCategoryMarkers>(_onAddCategoryMarkers);
    on<ClearCategoryMarkers>(_onClearCategoryMarkers);
    // Example: on<FetchMapRoutes>(_onFetchMapRoutes); // Handler for fetching routes (if implemented)

    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<_LocationUpdated>(
        _onLocationUpdated); // Internal event for location updates
    on<RateAndSaveRouteRequested>(_onRateAndSaveRouteRequested);
    on<DisplayRouteFromJson>(_onDisplayRouteFromJson);
  }

  /// Handles the [RequestLocationPermission] event.
  ///
  /// Requests the 'location when in use' permission from the user.
  Future<void> _onRequestLocationPermission(RequestLocationPermission event,
      Emitter<MapState> emit) async {
    await Permission.locationWhenInUse.request();
    // Note: State is not explicitly changed here, permission status is checked elsewhere.
  }

  /// Handles the [InitializeMap] event.
  ///
  /// Stores the provided [mapbox.MapboxMap] controller in the state,
  /// initializes the annotation managers, and triggers fetching the current location.
  Future<void> _onInitializeMap(InitializeMap event,
      Emitter<MapState> emit) async {
    emit(state.copyWith(mapController: event.mapController));
    // Initialize annotation managers after the map controller is available.
    _annotationManager =
    await state.mapController?.annotations.createPointAnnotationManager();
    _categoryAnnotationManager =
    await state.mapController?.annotations.createPointAnnotationManager();
    // Attempt to get the initial location once the map is ready.
    add(GetCurrentLocation());
  }

  /// Handles the [GetCurrentLocation] event.
  ///
  /// Checks for location permission, retrieves the current device location,
  /// and flies the map camera to that location. Emits an error message if
  /// permission is denied or location cannot be fetched.
  Future<void> _onGetCurrentLocation(GetCurrentLocation event,
      Emitter<MapState> emit) async {
    try {
      // Check current permission status.
      var status = await Permission.locationWhenInUse.status;
      // If permission is not granted, request it.
      if (!status.isGranted && !status.isLimited) {
        print("GetCurrentLocation: Permission not granted. Requesting...");
        status = await Permission.locationWhenInUse.request();
        // If permission is still denied after request, emit error state and return.
        if (!status.isGranted && !status.isLimited) {
          print("GetCurrentLocation: Permission denied after request.");
          emit(state.copyWith(
              errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας.')); // 'Location permission is required.'
          return;
        }
      }

      // Permission granted, get the current position.
      final position = await _geolocator.getCurrentPosition();
      final point = mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude));

      // Animate the camera to the user's location.
      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      // Update the zoom level in the state.
      emit(state.copyWith(zoomLevel: 16.0));

      // Placeholder for potentially adding styles or sources based on location.
      // await state.mapController?.style.addSource(...);

    } catch (e) {
      // Handle errors during location fetching or permission checks.
      print("Error getting current location: $e");
      emit(state.copyWith(
          errorMessageGetter: () => 'Αδυναμία λήψης τρέχουσας τοποθεσίας: $e')); // 'Failed to get current location: $e'
    }
  }

  /// Handles the [ZoomIn] event.
  ///
  /// Increases the map's zoom level by one and animates the camera.
  Future<void> _onZoomIn(ZoomIn event, Emitter<MapState> emit) async {
    final currentZoom = await state.mapController?.getCameraState();
    // Calculate the new zoom level, defaulting to state's zoomLevel if unavailable.
    final newZoom = (currentZoom?.zoom ?? state.zoomLevel) + 1;
    // Animate the camera to the new zoom level.
    state.mapController?.flyTo(
      mapbox.CameraOptions(zoom: newZoom),
      mapbox.MapAnimationOptions(duration: 500), // Shorter duration for zoom
    );
    // Update the zoom level in the state.
    emit(state.copyWith(zoomLevel: newZoom));
  }

  /// Handles the [ZoomOut] event.
  ///
  /// Decreases the map's zoom level by one and animates the camera.
  Future<void> _onZoomOut(ZoomOut event, Emitter<MapState> emit) async {
    final currentZoom = await state.mapController?.getCameraState();
    // Calculate the new zoom level, defaulting to state's zoomLevel if unavailable.
    final newZoom = (currentZoom?.zoom ?? state.zoomLevel) - 1;
    // Animate the camera to the new zoom level.
    state.mapController?.flyTo(
      mapbox.CameraOptions(zoom: newZoom),
      mapbox.MapAnimationOptions(duration: 500), // Shorter duration for zoom
    );
    // Update the zoom level in the state.
    emit(state.copyWith(zoomLevel: newZoom));
  }

  /// Handles the [FlyTo] event.
  ///
  /// Animates the map camera to the specified [event.latitude] and [event.longitude]
  /// with a fixed zoom level.
  Future<void> _onFlyTo(FlyTo event, Emitter<MapState> emit) async {
    final point = mapbox.Point(
        coordinates: mapbox.Position(event.longitude, event.latitude));
    // Animate the camera to the specified coordinates.
    state.mapController?.flyTo(
      mapbox.CameraOptions(center: point, zoom: 16.0),
      // Fly to a standard zoom level
      mapbox.MapAnimationOptions(duration: 1000), // Standard fly-to duration
    );
    // Optionally update the zoom level in state if desired:
    // emit(state.copyWith(zoomLevel: 16.0));
  }

  /// Handles the [AddMarker] event.
  ///
  /// Clears any existing single marker and adds a new one at the specified
  /// [event.latitude] and [event.longitude] using a custom pin image.
  Future<void> _onAddMarker(AddMarker event, Emitter<MapState> emit) async {
    final map = state.mapController;
    // Ensure map controller and annotation manager are initialized.
    if (map == null || _annotationManager == null) return;
    try {
      // Load the custom marker image from assets.
      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();
      final point = mapbox.Point(
          coordinates: mapbox.Position(event.longitude, event.latitude));

      // Clear previous single markers before adding a new one.
      await _annotationManager!.deleteAll();
      // Create the new point annotation.
      await _annotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.5, // Adjust size as needed
          image: imageData, // Use the loaded image data
          iconAnchor: mapbox.IconAnchor
              .BOTTOM, // Anchor the icon at its bottom center
        ),
      );
    } catch (e) {
      print("Error adding marker: $e");
      // Optionally emit an error state
    }
  }

  /// Handles the [DeleteMarker] event.
  ///
  /// Removes all markers managed by the single marker annotation manager.
  Future<void> _onDeleteMarker(DeleteMarker event,
      Emitter<MapState> emit) async {
    await _annotationManager?.deleteAll();
    // No state change needed unless tracking the marker's existence.
  }

  /// Handles the [AddCategoryMarkers] event.
  ///
  /// Adds multiple markers based on the provided list of [MapboxFeature]s.
  /// Uses the category annotation manager. If [event.shouldZoomToBounds] is true,
  /// calculates the bounding box of the markers and zooms/pans the map to fit them.
  Future<void> _onAddCategoryMarkers(AddCategoryMarkers event,
      Emitter<MapState> emit) async {
    final map = state.mapController;
    // Ensure map controller and category annotation manager are initialized.
    if (map == null || _categoryAnnotationManager == null) return;

    try {
      // Load the custom marker image from assets.
      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();
      final List<mapbox.PointAnnotationOptions> optionsList = [];
      // Variables to calculate bounding box.
      double? minLat, maxLat, minLng, maxLng;

      // Create annotation options for each feature.
      for (final feature in event.features) {
        final point = mapbox.Point(
            coordinates: mapbox.Position(feature.longitude, feature.latitude));
        optionsList.add(mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.4,
          // Slightly smaller size for category markers
          image: imageData,
          // Use the loaded image data
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          // Anchor at bottom center
          textField: feature.name, // Display feature name as text (optional)
        ));

        // Update bounding box coordinates.
        final lat = feature.latitude;
        final lng = feature.longitude;
        minLat = minLat == null ? lat : min(minLat, lat);
        maxLat = maxLat == null ? lat : max(maxLat, lat);
        minLng = minLng == null ? lng : min(minLng, lng);
        maxLng = maxLng == null ? lng : max(maxLng, lng);
      }
      // Create all annotations in a single batch call.
      final createdAnnotations = await _categoryAnnotationManager!.createMulti(
          optionsList);

      // Store the created annotations in the state (useful for potential interaction).
      emit(state.copyWith(
          categoryAnnotations: Set.from(createdAnnotations))); // Updated

      // If requested and bounds are valid, zoom to fit markers.
      if (event.shouldZoomToBounds && minLat != null && maxLat != null &&
          minLng != null && maxLng != null) {
        final southwest = mapbox.Point(
            coordinates: mapbox.Position(minLng, minLat));
        final northeast = mapbox.Point(
            coordinates: mapbox.Position(maxLng, maxLat));
        // Define the coordinate bounds.
        final bounds = mapbox.CoordinateBounds(southwest: southwest,
            northeast: northeast,
            infiniteBounds: false); // `infiniteBounds: false` is typical
        // Calculate the camera options needed to fit the bounds with padding.
        final cameraOptions = await map.cameraForCoordinateBounds(
          bounds,
          mapbox.MbxEdgeInsets(
              top: 50.0, left: 50.0, bottom: 50.0, right: 50.0),
          // Padding around bounds
          0.0, // Bearing
          0.0, // Pitch
          null, // Max Zoom
          null, // Offset
        );
        // Animate the camera to the calculated options.
        if (cameraOptions != null) {
          map.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 1000));
        }
      }
    } catch (e) {
      print("Error adding category markers: $e");
      // Optionally emit an error state
    }
  }

  /// Handles the [ClearCategoryMarkers] event.
  ///
  /// Removes all markers managed by the category annotation manager and clears
  /// the corresponding annotations from the state.
  Future<void> _onClearCategoryMarkers(ClearCategoryMarkers event,
      Emitter<MapState> emit) async {
    await _categoryAnnotationManager?.deleteAll();
    // Clear the stored category annotations in the state.
    emit(state.copyWith(categoryAnnotations: {}));
  }

  /// Handles the [StartTrackingRequested] event.
  ///
  /// Requests location permission if needed, sets up a location stream subscription
  /// using `geolocator`, and updates the state to indicate tracking has started.
  /// Emits error states if permission is denied or the stream fails to start.
  Future<void> _onStartTrackingRequested(StartTrackingRequested event,
      Emitter<MapState> emit) async {
    // ... (existing _onStartTrackingRequested logic remains the same) ...
    final permissionStatus = await Permission.locationWhenInUse.request();
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      emit(state.copyWith(
        trackingStatus: MapTrackingStatus.loading,
        trackedRoute: [],
        // Always clear route on new start
        currentTrackedPositionGetter: () => null,
        isTracking: false,
        errorMessageGetter: () => null,
      ));
      await _stopTrackingLogic(); // Ensure any previous tracking is stopped

      const locationSettings = geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high, distanceFilter: 5,);
      try {
        _positionSubscription = _geolocator
            .getPositionStream(locationSettings: locationSettings)
            .handleError((error) {
          print("Error in location stream: $error");
          add(StopTrackingRequested());
          emit(state.copyWith(
              trackingStatus: MapTrackingStatus.error,
              isTracking: false,
              errorMessageGetter: () => 'Σφάλμα ροής τοποθεσίας: $error'));
        })
            .listen((geolocator.Position position) {
          add(_LocationUpdated(position));
        });
        emit(state.copyWith(
          isTracking: true, trackingStatus: MapTrackingStatus.tracking,));
        print("Tracking started...");
      } catch (e) {
        print("Error starting location stream: $e");
        await _stopTrackingLogic();
        emit(state.copyWith(
            trackingStatus: MapTrackingStatus.error, isTracking: false,
            errorMessageGetter: () => 'Αδυναμία έναρξης παρακολούθησης: $e'));
      }
    } else {
      print("Location permission denied for tracking.");
      emit(state.copyWith(
          trackingStatus: MapTrackingStatus.error,
          errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας για την έναρξη καταγραφής.'));
    }
  }

  /// Handles the internal [_LocationUpdated] event.
  ///
  /// This is triggered by the location stream when tracking is active.
  /// It adds the new [event.newPosition] to the tracked route in the state.
  void _onLocationUpdated(_LocationUpdated event, Emitter<MapState> emit) {
    if (!state.isTracking) return;
    final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)
      ..add(event.newPosition);
    emit(state.copyWith(
      currentTrackedPositionGetter: () => event.newPosition,
      trackedRoute: updatedRoute,
    ));
  }

  /// Handles the [StopTrackingRequested] event.
  ///
  /// Calls the internal [_stopTrackingLogic] to cancel the location stream
  /// subscription and updates the state to indicate tracking has stopped.
  Future<void> _onStopTrackingRequested(StopTrackingRequested event,
      Emitter<MapState> emit) async {
    await _stopTrackingLogic(); // Cancel the stream subscription.
    // Update the state to reflect that tracking is no longer active.
    emit(state.copyWith(
      isTracking: false,
      trackingStatus: MapTrackingStatus.stopped,
      // trackedRoute: [], // <-- ΑΛΛΑΓΗ: Αφαιρέθηκε ή έγινε σχόλιο για να μην καθαρίζει η διαδρομή
    ));
    print("Tracking stopped (without rating). Final points: ${state.trackedRoute
        .length}");
    // NOTE: No data is saved here.
  }

  // --- NEW Handler for Rating and Saving --- // <-- ΝΕΟ
  /// Handles the [RateAndSaveRouteRequested] event.
  /// Saves the rated route to Firestore and updates the state to stop tracking.
  Future<void> _onRateAndSaveRouteRequested(RateAndSaveRouteRequested event,
      Emitter<MapState> emit) async {
    // It's implied tracking was active. Stop the location updates first.
    await _stopTrackingLogic();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("User not logged in, cannot save rated route.");
      emit(state.copyWith(
        isTracking: false,
        trackingStatus: MapTrackingStatus.error, // Indicate error
        errorMessageGetter: () => 'User not logged in to save route.',
        // Keep the route data in state if needed for display
      ));
      return;
    }

    // Optionally emit a 'saving' status if you want UI feedback
    // emit(state.copyWith(trackingStatus: MapTrackingStatus.saving));

    try {
      print("Saving rated route to Firestore for user ${currentUser.uid}...");

      // Convert List<Position> to List<Map<String, dynamic>> for Firestore
      final List<Map<String, dynamic>> routeForFirestore = event.route.map((
          pos) =>
      {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'altitude': pos.altitude,
        'accuracy': pos.accuracy,
        'speed': pos.speed,
        'timestamp': pos.timestamp..toIso8601String(),
        // Convert DateTime to ISO 8601 String
      }).toList();

      // Prepare the data document
      final Map<String, dynamic> ratedRouteData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'rating': event.rating, // 'green', 'yellow', or 'red'
        'routePoints': routeForFirestore,
        'pointCount': event.route.length,
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        // You could add start/end timestamps if you track them
      };

      // Save to Firestore collection 'rated_routes'
      await _firestore.collection('rated_routes').add(ratedRouteData);

      print("Rated route saved successfully!");

      // Update state: stop tracking, set status, clear errors
      emit(state.copyWith(
        isTracking: false,
        // Tracking is now stopped
        trackingStatus: MapTrackingStatus.stopped,
        // Status is stopped
        // trackedRoute: [], // DECIDE: Clear route from state/map now? Or leave it? Let's leave it for now.
        errorMessageGetter: () => null, // Clear any previous error
      ));
    } catch (e) {
      print("Error saving rated route: $e");
      // Update state: stop tracking, set status to error
      emit(state.copyWith(
        isTracking: false, // Still stop tracking
        trackingStatus: MapTrackingStatus.error, // Set error status
        errorMessageGetter: () => 'Failed to save rated route: $e',
        // Keep route data in state for potential retry or display
      ));
    }
  }

  /// Internal helper method to cancel the location stream subscription.
  ///
  /// Safely cancels the [_positionSubscription] if it exists and sets it to null.
  Future<void> _stopTrackingLogic() async {
    print("Stopping location subscription...");
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Overrides the BLoC's close method for cleanup.
  ///
  /// Ensures the location stream subscription is cancelled when the BLoC is disposed.
  @override
  Future<void> close() {
    print("Closing MapBloc, cancelling subscription...");
    _positionSubscription?.cancel(); // Ensure cleanup on BLoC disposal
    return super.close();
  }

  Future<void> _onDisplayRouteFromJson(DisplayRouteFromJson event,
      Emitter<MapState> emit,) async {
    try {
      final map = state.mapController;
      if (map == null) {
        emit(state.copyWith(
            errorMessageGetter: () => 'Map controller not ready'));
        return;
      }

      final coordinates = event.routeJson['route'];
      if (coordinates == null || coordinates is! List) {
        emit(state.copyWith(errorMessageGetter: () => 'Route data is invalid'));
        return;
      }

      final lineCoordinates = coordinates.map<List<double>>((c) {
        if (c is List && c.length >= 2) {
          return [c[0].toDouble(), c[1].toDouble()]; // [lng, lat]
        } else {
          throw Exception('Invalid coordinate format');
        }
      }).toList();

      final geojson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": lineCoordinates,
            },
            "properties": {}
          }
        ]
      };

      const sourceId = 'route-source';
      const layerId = 'route-layer';

      final style = map.style;

      await style.removeStyleLayer(layerId).catchError((_) {});
      await style.removeStyleSource(sourceId).catchError((_) {});

      await style.addSource(
        mapbox.GeoJsonSource(
          id: sourceId,
          data: jsonEncode(geojson),
        ),
      );

      await style.addLayer(
        mapbox.LineLayer(
          id: layerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
        ),
      );

      emit(state.copyWith(errorMessageGetter: () => null));
    } catch (e) {
      emit(state.copyWith(
          errorMessageGetter: () => 'Error displaying route: $e'));
    }
  }
}

class LineLayerProperties {
}

class GeoJsonSourceProperties {
}