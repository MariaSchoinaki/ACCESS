part of 'map_bloc.dart';

// Enum for the state of tracking
enum MapTrackingStatus { initial, loading, tracking, stopped, error }

/// Holds the current state of the map, including controller, zoom level, routes, and tracking info
class MapState extends Equatable {
  /// The Mapbox map controller
  final mapbox.MapboxMap? mapController;
  /// The zoom level of the map
  final double zoomLevel;
  /// List of main route coordinates displayed on the map
  final List<List<double>> mainRoute;
  /// List of alternative routes (each is a list of coordinates)
  final List<List<List<double>>> alternativeRoutes;
  /// Annotations related to categories (e.g., points of interest, POI)
  final Set<mapbox.PointAnnotation> categoryAnnotations;
  /// A map that associates Mapbox IDs with internal IDs. Map<InternalId, MapboxId>
  final Map<String, String> annotationIdMap;

  // --- Properties for tracking ---
  final bool isTracking;
  final List<geolocator.Position> trackedRoute;
  final geolocator.Position? currentTrackedPosition;
  final MapTrackingStatus trackingStatus;
  final String? errorMessage;

  // Constructor with default values
  const MapState({
    this.mapController,
    this.zoomLevel = 14.0,
    this.mainRoute = const [],
    this.alternativeRoutes = const [],
    this.categoryAnnotations = const {},
    this.annotationIdMap = const {},
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
    List<List<double>>? mainRoute,
    List<List<List<double>>>? alternativeRoutes,
    Set<mapbox.PointAnnotation>? categoryAnnotations,
    Map<String, String>? annotationIdMap,
    bool? isTracking,
    List<geolocator.Position>? trackedRoute,
    ValueGetter<geolocator.Position?>? currentTrackedPositionGetter,
    MapTrackingStatus? trackingStatus,
    ValueGetter<String?>? errorMessageGetter,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      mainRoute: mainRoute ?? this.mainRoute,
      alternativeRoutes: alternativeRoutes ?? this.alternativeRoutes,
      categoryAnnotations: categoryAnnotations ?? this.categoryAnnotations,
      annotationIdMap: annotationIdMap ?? this.annotationIdMap,
      isTracking: isTracking ?? this.isTracking,
      trackedRoute: trackedRoute ?? this.trackedRoute,
      currentTrackedPosition: currentTrackedPositionGetter != null
          ? currentTrackedPositionGetter()
          : this.currentTrackedPosition,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      errorMessage: errorMessageGetter != null
          ? errorMessageGetter()
          : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    mapController,
    zoomLevel,
    mainRoute,
    alternativeRoutes,
    categoryAnnotations,
    annotationIdMap,
    isTracking,
    trackedRoute,
    currentTrackedPosition,
    trackingStatus,
    errorMessage,
  ];
}

// Class for requesting details of a specific POI (Point of Interest) based on the mapboxId
class _PoiDetailsRequested extends MapState {
  final String mapboxId;
  _PoiDetailsRequested(this.mapboxId);
}

/// State emitted when a specific point annotation (marker) on the map is clicked.
/// Contains the ID needed to retrieve more details about the annotation.
class MapAnnotationClicked extends MapState {
  /// The unique identifier (e.g., Mapbox ID) of the clicked annotation.
  final String mapboxId;

  MapAnnotationClicked(this.mapboxId, MapState previousState) : super(
    mapController: previousState.mapController,
    zoomLevel: previousState.zoomLevel,
    trackedRoute: previousState.trackedRoute,
    isTracking: previousState.isTracking,
    trackingStatus: previousState.trackingStatus,
    currentTrackedPosition: previousState.currentTrackedPosition,
    categoryAnnotations: previousState.categoryAnnotations,
    annotationIdMap: previousState.annotationIdMap,
  );

  @override
  List<Object?> get props => [mapboxId];
}