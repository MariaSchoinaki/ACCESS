import 'dart:async'; // Για StreamSubscription
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Για ValueGetter
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import '../../models/mapbox_feature.dart';

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
  final geolocator.GeolocatorPlatform _geolocator = geolocator.GeolocatorPlatform.instance;

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
    on<_LocationUpdated>(_onLocationUpdated); // Internal event for location updates
  }

  /// Handles the [RequestLocationPermission] event.
  ///
  /// Requests the 'location when in use' permission from the user.
  Future<void> _onRequestLocationPermission(RequestLocationPermission event, Emitter<MapState> emit) async {
    await Permission.locationWhenInUse.request();
    // Note: State is not explicitly changed here, permission status is checked elsewhere.
  }

  /// Handles the [InitializeMap] event.
  ///
  /// Stores the provided [mapbox.MapboxMap] controller in the state,
  /// initializes the annotation managers, and triggers fetching the current location.
  Future<void> _onInitializeMap(InitializeMap event, Emitter<MapState> emit) async {
    emit(state.copyWith(mapController: event.mapController));
    // Initialize annotation managers after the map controller is available.
    _annotationManager = await state.mapController?.annotations.createPointAnnotationManager();
    _categoryAnnotationManager = await state.mapController?.annotations.createPointAnnotationManager();
    // Attempt to get the initial location once the map is ready.
    add(GetCurrentLocation());
  }

  /// Handles the [GetCurrentLocation] event.
  ///
  /// Checks for location permission, retrieves the current device location,
  /// and flies the map camera to that location. Emits an error message if
  /// permission is denied or location cannot be fetched.
  Future<void> _onGetCurrentLocation(GetCurrentLocation event, Emitter<MapState> emit) async {
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
          emit(state.copyWith(errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας.')); // 'Location permission is required.'
          return;
        }
      }

      // Permission granted, get the current position.
      final position = await _geolocator.getCurrentPosition();
      final point = mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude));

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
      emit(state.copyWith(errorMessageGetter: () => 'Αδυναμία λήψης τρέχουσας τοποθεσίας: $e')); // 'Failed to get current location: $e'
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
    final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));
    // Animate the camera to the specified coordinates.
    state.mapController?.flyTo(
      mapbox.CameraOptions(center: point, zoom: 16.0), // Fly to a standard zoom level
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
      final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));

      // Clear previous single markers before adding a new one.
      await _annotationManager!.deleteAll();
      // Create the new point annotation.
      await _annotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.5,          // Adjust size as needed
          image: imageData,       // Use the loaded image data
          iconAnchor: mapbox.IconAnchor.BOTTOM, // Anchor the icon at its bottom center
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
  Future<void> _onDeleteMarker(DeleteMarker event, Emitter<MapState> emit) async {
    await _annotationManager?.deleteAll();
    // No state change needed unless tracking the marker's existence.
  }

  /// Handles the [AddCategoryMarkers] event.
  ///
  /// Adds multiple markers based on the provided list of [MapboxFeature]s.
  /// Uses the category annotation manager. If [event.shouldZoomToBounds] is true,
  /// calculates the bounding box of the markers and zooms/pans the map to fit them.
  Future<void> _onAddCategoryMarkers(AddCategoryMarkers event, Emitter<MapState> emit) async {
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
        final point = mapbox.Point(coordinates: mapbox.Position(feature.longitude, feature.latitude));
        optionsList.add(mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.4,            // Slightly smaller size for category markers
          image: imageData,         // Use the loaded image data
          iconAnchor: mapbox.IconAnchor.BOTTOM, // Anchor at bottom center
          textField: feature.name, // Display feature name as text (optional)
        ));

        // Update bounding box coordinates.
        final lat = feature.latitude; final lng = feature.longitude;
        minLat = minLat == null ? lat : min(minLat, lat);
        maxLat = maxLat == null ? lat : max(maxLat, lat);
        minLng = minLng == null ? lng : min(minLng, lng);
        maxLng = maxLng == null ? lng : max(maxLng, lng);
      }
      // Create all annotations in a single batch call.
      final createdAnnotations = await _categoryAnnotationManager!.createMulti(optionsList);

      // Store the created annotations in the state (useful for potential interaction).
      emit(state.copyWith(categoryAnnotations: Set.from(createdAnnotations))); // Updated

      // If requested and bounds are valid, zoom to fit markers.
      if (event.shouldZoomToBounds && minLat != null && maxLat != null && minLng != null && maxLng != null) {
        final southwest = mapbox.Point(coordinates: mapbox.Position(minLng, minLat));
        final northeast = mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat));
        // Define the coordinate bounds.
        final bounds = mapbox.CoordinateBounds(southwest: southwest, northeast: northeast, infiniteBounds: false); // `infiniteBounds: false` is typical
        // Calculate the camera options needed to fit the bounds with padding.
        final cameraOptions = await map.cameraForCoordinateBounds(
          bounds,
          mapbox.MbxEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), // Padding around bounds
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
  Future<void> _onClearCategoryMarkers(ClearCategoryMarkers event, Emitter<MapState> emit) async {
    await _categoryAnnotationManager?.deleteAll();
    // Clear the stored category annotations in the state.
    emit(state.copyWith(categoryAnnotations: {}));
  }

  /// Handles the [StartTrackingRequested] event.
  ///
  /// Requests location permission if needed, sets up a location stream subscription
  /// using `geolocator`, and updates the state to indicate tracking has started.
  /// Emits error states if permission is denied or the stream fails to start.
  Future<void> _onStartTrackingRequested(
      StartTrackingRequested event, Emitter<MapState> emit) async {
    // 1. Check for permission
    final permissionStatus = await Permission.locationWhenInUse.request();

    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      // Permission granted, proceed with tracking setup.
      // 2. Preparation & Start Stream
      emit(state.copyWith(
        trackingStatus: MapTrackingStatus.loading, // Indicate loading state
        trackedRoute: [], // Clear any previous route data
        currentTrackedPositionGetter: () => null, // Reset current position
        isTracking: false, // Ensure tracking flag is reset before starting
        errorMessageGetter: () => null, // Clear previous errors
      ));

      // Stop any existing tracking subscription before starting a new one.
      await _stopTrackingLogic();

      // Configure location stream settings (high accuracy, update every 5 meters).
      const locationSettings = geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 5, // meters
      );

      try {
        // Start listening to the position stream.
        _positionSubscription = _geolocator
            .getPositionStream(locationSettings: locationSettings)
        // Handle potential errors within the stream.
            .handleError((error) {
          print("Error in location stream: $error");
          // If stream errors, stop tracking and emit error state.
          add(StopTrackingRequested()); // Trigger stop logic internally
          emit(state.copyWith(
              trackingStatus: MapTrackingStatus.error,
              isTracking: false, // Ensure tracking is marked as stopped
              errorMessageGetter: () => 'Σφάλμα ροής τοποθεσίας: $error')); // 'Location stream error: $error'
        })
        // Listen for new position updates.
            .listen((geolocator.Position position) {
          // Add an internal event to handle the location update.
          add(_LocationUpdated(position));
        });

        // Update state to indicate tracking is active.
        emit(state.copyWith(
          isTracking: true,
          trackingStatus: MapTrackingStatus.tracking,
        ));
        print("Tracking started...");
      } catch (e) {
        // Handle errors during stream setup.
        print("Error starting location stream: $e");
        await _stopTrackingLogic(); // Ensure cleanup if start fails
        emit(state.copyWith(
            trackingStatus: MapTrackingStatus.error,
            isTracking: false,
            errorMessageGetter: () => 'Αδυναμία έναρξης παρακολούθησης: $e')); // 'Failed to start tracking: $e'
      }

    } else {
      // Permission was not granted.
      print("Location permission denied for tracking.");
      emit(state.copyWith(
          trackingStatus: MapTrackingStatus.error,
          errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας για την έναρξη καταγραφής.')); // 'Location permission required to start recording.'
    }
  }

  /// Handles the internal [_LocationUpdated] event.
  ///
  /// This is triggered by the location stream when tracking is active.
  /// It adds the new [event.newPosition] to the tracked route in the state.
  void _onLocationUpdated(_LocationUpdated event, Emitter<MapState> emit) {
    // Ignore updates if tracking is not currently active.
    if (!state.isTracking) return;

    // Create an updated list of positions for the tracked route.
    final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)
      ..add(event.newPosition); // Add the new position

    // Update the state with the new position and the extended route.
    emit(state.copyWith(
      currentTrackedPositionGetter: () => event.newPosition, // Update the latest known position
      trackedRoute: updatedRoute, // Update the list of tracked points
      // trackingStatus remains MapTrackingStatus.tracking
    ));
    // Optional debug print:
    // print("Tracked route points: ${updatedRoute.length}");
  }

  /// Handles the [StopTrackingRequested] event.
  ///
  /// Calls the internal [_stopTrackingLogic] to cancel the location stream
  /// subscription and updates the state to indicate tracking has stopped.
  Future<void> _onStopTrackingRequested(
      StopTrackingRequested event, Emitter<MapState> emit) async {
    await _stopTrackingLogic(); // Perform the actual subscription cancellation.
    // Update the state to reflect that tracking is no longer active.
    emit(state.copyWith(
      isTracking: false,
      trackingStatus: MapTrackingStatus.stopped,
    ));
    print("Tracking stopped. Final points: ${state.trackedRoute.length}");
    /// TODO: Implement logic to send/save the recorded state.trackedRoute data.
  }

  /// Internal helper method to cancel the location stream subscription.
  ///
  /// Safely cancels the [_positionSubscription] if it exists and sets it to null.
  Future<void> _stopTrackingLogic() async {
    print("Stopping location subscription...");
    await _positionSubscription?.cancel(); // Cancel the stream subscription
    _positionSubscription = null;        // Nullify the subscription variable
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
}