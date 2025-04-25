part of 'map_bloc.dart';

/// Holds the current state of the map including controller, zoom, and annotations
class MapState {
  final mapbox.MapboxMap? mapController;
  final double zoomLevel;
  final List<dynamic> routes;
  final Set<mapbox.PointAnnotation> categoryAnnotations; // Store category markers

  MapState({
    this.mapController,
    this.zoomLevel = 14.0,
    this.routes = const [],
    this.categoryAnnotations = const {},
  });

  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
    List<dynamic>? routes,
    Set<mapbox.PointAnnotation>? categoryAnnotations,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      routes: routes ?? this.routes,
      categoryAnnotations: categoryAnnotations ?? this.categoryAnnotations,
    );
  }
}
class _PoiDetailsRequested extends MapState {
  final String mapboxId;

  _PoiDetailsRequested(this.mapboxId);
}