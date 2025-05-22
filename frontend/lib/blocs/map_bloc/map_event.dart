part of 'map_bloc.dart';

/// Base class for all map-related events
abstract class MapEvent {}

/// Requests location permission from the user
class RequestLocationPermission extends MapEvent {}

/// Gets the current geolocation of the user
class GetCurrentLocation extends MapEvent {}

/// Zooms in on the map
class ZoomIn extends MapEvent {}

/// Zooms out on the map
class ZoomOut extends MapEvent {}

/// Initializes the map with the provided controller
class InitializeMap extends MapEvent {
  // The Mapbox map controller that will be initialized
  final mapbox.MapboxMap mapController;

  InitializeMap(this.mapController);
}

/// Moves the camera to a specific latitude and longitude
class FlyTo extends MapEvent {
  // Latitude of the location to fly to
  final double latitude;
  // Longitude of the location to fly to
  final double longitude;

  FlyTo(this.latitude, this.longitude);
}

/// Adds a marker to a specified location (e.g., after a long tap)
class AddMarker extends MapEvent {
  // Latitude of the location where the marker will be added
  final double latitude;
  // Longitude of the location where the marker will be added
  final double longitude;

  AddMarker(this.latitude, this.longitude);
}

/// Deletes all existing markers on the map (e.g., after long tap markers)
class DeleteMarker extends MapEvent {
  DeleteMarker();
}

/// Adds multiple markers for category search results
class AddCategoryMarkers extends MapEvent {
  // List of Mapbox features to represent as markers
  final List<MapboxFeature> features;
  // Flag to determine whether to zoom to the bounds of the added markers
  final bool shouldZoomToBounds;

  AddCategoryMarkers(this.features, {this.shouldZoomToBounds = false});
}

/// Private event triggered when a category marker is clicked
class _AnnotationClickedInternal extends MapEvent {
  final String mapboxId;
  final MapboxFeature feature;

  _AnnotationClickedInternal(this.mapboxId, this.feature);

  @override
  List<Object> get props => [mapboxId];
}

/// Clears all category markers from the map
class ClearCategoryMarkers extends MapEvent {}

/// Fetches route overlays or geometries from the map microservice
class FetchMapRoutes extends MapEvent {}

/// Event to start tracking the user's location
class StartTrackingRequested extends MapEvent {}

/// Event to stop tracking the user's location
class StopTrackingRequested extends MapEvent {}

/// Event to rate and save the completed route.
class RateAndSaveRouteRequested extends MapEvent {
  final double rating;
  final List<geolocator.Position> route; // The tracked points

  RateAndSaveRouteRequested({required this.rating, required this.route});

  @override
  List<Object?> get props => [rating, route];
}

/// Event when the location of the user is updated
class _LocationUpdated extends MapEvent {
  // New location of the user
  final geolocator.Position newPosition;

  _LocationUpdated(this.newPosition);
}

class DisplayRouteFromJson extends MapEvent {
  final Map<String, dynamic> routeJson;

  DisplayRouteFromJson(this.routeJson);

  @override
  List<Object> get props => [routeJson];
}

class DisplayAlternativeRoutesFromJson extends MapEvent {
  final List<List<List<double>>> routes; // List of routes (each route = list of [lng, lat])

  DisplayAlternativeRoutesFromJson(this.routes);

  @override
  List<Object?> get props => [routes];
}

class ShareLocationRequested extends MapEvent {
  final String location;
  ShareLocationRequested(this.location);
}

class LaunchPhoneDialerRequested extends MapEvent {
  final String? phoneNumber;
  LaunchPhoneDialerRequested(this.phoneNumber);
}

// Navigation Events
class StartNavigationRequested extends MapEvent {

  StartNavigationRequested();
}

class UpdateNavigationStep extends MapEvent {
  final int currentStepIndex;

  UpdateNavigationStep(this.currentStepIndex);
}

class StopNavigationRequested extends MapEvent {}

class ToggleVoiceInstructions extends MapEvent {}


class NavigationPositionUpdated extends MapEvent {
  final geolocator.Position position;

  NavigationPositionUpdated(this.position);
}