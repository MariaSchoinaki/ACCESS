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
  final List<dynamic> alternativeRoutes;
  /// Annotations related to categories (e.g., points of interest, POI)
  final Set<mapbox.PointAnnotation> categoryAnnotations;
  /// A map that associates Mapbox IDs with internal IDs. Map<InternalId, MapboxId>
  final Map<String, String> annotationIdMap;
  /// A map that associates Mapbox IDs with MapboxFeature objects. Map<MapboxId, MapboxFeature>
  final Map<String, MapboxFeature> featureMap;

  // --- Properties for navigation ---
  /// List of navigation steps for the current route
  final List<NavigationStep> routeSteps;
  /// Whether the user is currently navigating
  final bool isNavigating;
  /// The index of the current navigation step
  final int currentStepIndex;
  /// Whether voice instructions are enabled
  final bool isVoiceEnabled;

  final bool showAlternatives;


  // --- Properties for tracking ---
  /// Whether the user is currently tracking its location
  final bool isTracking;
  /// List of tracked route coordinates
  final List<geolocator.Position> trackedRoute;
  /// The current tracked position
  final geolocator.Position? currentTrackedPosition;
  /// The current status of tracking
  final MapTrackingStatus trackingStatus;
  /// Error message if tracking fails
  final String? errorMessage;
  final bool isCameraFollowing;
  final bool isOffRoute;
  final MapEvent? lastEvent;

  // Constructor with default values
  const MapState({
    this.mapController,
    this.zoomLevel = 14.0,
    this.mainRoute = const [],
    this.alternativeRoutes = const [],
    this.categoryAnnotations = const {},
    this.annotationIdMap = const {},
    this.featureMap = const {},
    this.isTracking = false,
    this.trackedRoute = const [],
    this.currentTrackedPosition,
    this.trackingStatus = MapTrackingStatus.initial,
    this.errorMessage,
    this.routeSteps = const [],
    this.isNavigating = false,
    this.currentStepIndex = 0,
    this.isVoiceEnabled = true,
    this.showAlternatives = false,
    this.isCameraFollowing = false,
    this.isOffRoute = false,
    this.lastEvent,
  });

  // Returns the initial state
  factory MapState.initial() => const MapState();

  // Method to copy the current state with new values for fields
  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
    List<List<double>>? mainRoute,
    List<dynamic>? alternativeRoutes,
    Set<mapbox.PointAnnotation>? categoryAnnotations,
    Map<String, String>? annotationIdMap,
    Map<String, MapboxFeature>? featureMap,
    bool? isTracking,
    List<geolocator.Position>? trackedRoute,
    ValueGetter<geolocator.Position?>? currentTrackedPositionGetter,
    MapTrackingStatus? trackingStatus,
    ValueGetter<String?>? errorMessageGetter,
    List<NavigationStep>? routeSteps,
    bool? isNavigating,
    int? currentStepIndex,
    bool? isVoiceEnabled,
    bool? showAlternatives,
    bool? isCameraFollowing,
    bool? isOffRoute,
    MapEvent? lastEvent,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      mainRoute: mainRoute ?? this.mainRoute,
      alternativeRoutes: alternativeRoutes ?? this.alternativeRoutes,
      categoryAnnotations: categoryAnnotations ?? this.categoryAnnotations,
      annotationIdMap: annotationIdMap ?? this.annotationIdMap,
      featureMap: featureMap ?? this.featureMap,
      isTracking: isTracking ?? this.isTracking,
      trackedRoute: trackedRoute ?? this.trackedRoute,
      currentTrackedPosition: currentTrackedPositionGetter != null
          ? currentTrackedPositionGetter()
          : this.currentTrackedPosition,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      errorMessage: errorMessageGetter != null
          ? errorMessageGetter()
          : this.errorMessage,
      routeSteps: routeSteps ?? this.routeSteps,
      isNavigating: isNavigating ?? this.isNavigating,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      showAlternatives: showAlternatives ?? this.showAlternatives,
      isCameraFollowing: isCameraFollowing ?? this.isCameraFollowing,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      lastEvent: lastEvent ?? this.lastEvent,

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
    featureMap,
    isTracking,
    trackedRoute,
    currentTrackedPosition,
    trackingStatus,
    errorMessage,
    routeSteps,
    isNavigating,
    currentStepIndex,
    isVoiceEnabled,
    showAlternatives,
    isCameraFollowing,
    isOffRoute,
    lastEvent,
  ];
}

/// State emitted when a specific point annotation (marker) on the map is clicked.
/// Contains the ID needed to retrieve more details about the annotation.
class MapAnnotationClicked extends MapState {
  /// The unique identifier (e.g., Mapbox ID) of the clicked annotation.
  final String mapboxId;
  final MapboxFeature feature;

  MapAnnotationClicked(this.mapboxId, this.feature, MapState previousState) : super(
    mapController: previousState.mapController,
    zoomLevel: previousState.zoomLevel,
    trackedRoute: previousState.trackedRoute,
    isTracking: previousState.isTracking,
    trackingStatus: previousState.trackingStatus,
    currentTrackedPosition: previousState.currentTrackedPosition,
    categoryAnnotations: previousState.categoryAnnotations,
    annotationIdMap: previousState.annotationIdMap,
    featureMap: previousState.featureMap,
    mainRoute: previousState.mainRoute,
    alternativeRoutes: previousState.alternativeRoutes,
    errorMessage: previousState.errorMessage,
  );

  @override
  List<Object?> get props => [mapboxId, feature];
}

class ActionCompleted extends MapState {}

class ActionFailed extends MapState {
  final String message;
  ActionFailed(this.message);
}