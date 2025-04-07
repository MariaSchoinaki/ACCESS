import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

abstract class MapEvent {}

class RequestLocationPermission extends MapEvent {}

class GetCurrentLocation extends MapEvent {}

class ZoomIn extends MapEvent {}

class ZoomOut extends MapEvent {}

class InitializeMap extends MapEvent {
  final mapbox.MapboxMap mapController;
  InitializeMap(this.mapController);
}