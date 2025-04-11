import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapState {
  final mapbox.MapboxMap? mapController;
  final double zoomLevel;

  MapState({
    this.mapController,
    this.zoomLevel = 14.0,
  });

  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}
