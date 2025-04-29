part of 'map_bloc.dart';

// Enum for the state of tracking
enum MapTrackingStatus { initial, loading, tracking, stopped, error }

/// Holds the current state of the map including controller, zoom, annotations, and tracking info
class MapState extends Equatable {
  final mapbox.MapboxMap? mapController;
  final double zoomLevel;
  final List<dynamic> routes;
  final Set<mapbox.PointAnnotation> categoryAnnotations;

  // --- properties for tracking ---
  final bool isTracking;
  final List<geolocator.Position> trackedRoute;
  final geolocator.Position? currentTrackedPosition;
  final MapTrackingStatus trackingStatus;
  final String? errorMessage;

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

  factory MapState.initial() => const MapState();

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
    routes,
    categoryAnnotations,
    isTracking,
    trackedRoute,
    currentTrackedPosition,
    trackingStatus,
    errorMessage,
  ];
}

 class _PoiDetailsRequested extends MapState {
   final String mapboxId;
   _PoiDetailsRequested(this.mapboxId);
}