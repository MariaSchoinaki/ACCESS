part of 'map_bloc.dart';

/// Holds the current state of the map including controller and zoom
class MapState {
  final mapbox.MapboxMap? mapController;
  final double zoomLevel;
  final List<dynamic> routes; // Add any type based on your backend response

  MapState({
    this.mapController,
    this.zoomLevel = 14.0,
    this.routes = const [],
  });

  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
    List<dynamic>? routes,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      routes: routes ?? this.routes,
    );
  }
}
