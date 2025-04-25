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
  final mapbox.MapboxMap mapController;

  InitializeMap(this.mapController);
}

/// Moves the camera to a specific latitude and longitude
class FlyTo extends MapEvent {
  final double latitude;
  final double longitude;

  FlyTo(this.latitude, this.longitude);
}

/// Adds a marker to a specified location (e.g., long tap)
class AddMarker extends MapEvent {
  final double latitude;
  final double longitude;

  AddMarker(this.latitude, this.longitude);
}

/// Deletes all existing markers on the map (long tap markers)
class DeleteMarker extends MapEvent {
  DeleteMarker();
}

/// Adds multiple markers for category search results
class AddCategoryMarkers extends MapEvent {
  final List<MapboxFeature> features;
  final bool shouldZoomToBounds; // New parameter

  AddCategoryMarkers(this.features, {this.shouldZoomToBounds = false});
}

/// Clears all category markers from the map
class ClearCategoryMarkers extends MapEvent {}

/// Fetches route overlays or geometries from the map microservice
class FetchMapRoutes extends MapEvent {}