part of 'map_bloc.dart';

// Enum for the state of tracking
enum MapTrackingStatus { initial, loading, tracking, stopped, error }

/// Holds the current state of the map, including controller, zoom level, routes, and tracking info
class MapState extends Equatable {
  // The Mapbox map controller
  final mapbox.MapboxMap? mapController;
  // The zoom level of the map
  final double zoomLevel;
  // List of routes displayed on the map
  final List<dynamic> routes;
  // Annotations related to categories (e.g., points of interest, POI)
  final Set<mapbox.PointAnnotation> categoryAnnotations;

  // --- Properties for tracking ---
  // Indicates whether tracking is active
  final bool isTracking;
  // The route being tracked (list of positions)
  final List<geolocator.Position> trackedRoute;
  // The current tracked position
  final geolocator.Position? currentTrackedPosition;
  // Tracking status (e.g., initial, in progress, stopped, error)
  final MapTrackingStatus trackingStatus;
  // Error message if any
  final String? errorMessage;

  // Constructor with default values
  const MapState({
    this.mapController,
    this.zoomLevel = 14.0,
    this.routes = const [],
    this.categoryAnnotations = const {},
    this.isTracking = false,
    this.trackedRoute = const [],
    this.currentTrackedPosition,
    this.trackingStatus = MapTrackingStatus.initial,
    this.errorMessage,
  });

  // Returns the initial state
  factory MapState.initial() => const MapState();

  // Method to copy the current state with new values for fields
  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
    List<dynamic>? routes,
    Set<mapbox.PointAnnotation>? categoryAnnotations,
    bool? isTracking,
    List<geolocator.Position>? trackedRoute,
    ValueGetter<geolocator.Position?>? currentTrackedPositionGetter,
    MapTrackingStatus? trackingStatus,
    ValueGetter<String?>? errorMessageGetter,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      routes: routes ?? this.routes,
      categoryAnnotations: categoryAnnotations ?? this.categoryAnnotations,
      isTracking: isTracking ?? this.isTracking,
      trackedRoute: trackedRoute ?? this.trackedRoute,
      // Returns the current tracked position based on a getter if available
      currentTrackedPosition: currentTrackedPositionGetter != null
          ? currentTrackedPositionGetter()
          : this.currentTrackedPosition,
      // Returns the tracking status, uses the current one if not provided
      trackingStatus: trackingStatus ?? this.trackingStatus,
      // Returns the error message, uses the current one if not provided
      errorMessage: errorMessageGetter != null
          ? errorMessageGetter()
          : this.errorMessage,
    );
  }

  // Comparison of properties for equality (used by Equatable)
  @override
  List<Object?> get props => [
    mapController,
    zoomLevel,
    routes,
    categoryAnnotations,
    isTracking,
    trackedRoute,
    currentTrackedPosition,
    trackingStatus,
    errorMessage,
  ];
}

// Class for requesting details of a specific POI (Point of Interest) based on the mapboxId
class _PoiDetailsRequested extends MapState {
  // The mapboxId of the POI
  final String mapboxId;

  // Constructor
  _PoiDetailsRequested(this.mapboxId);
}