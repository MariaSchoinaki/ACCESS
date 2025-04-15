import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

/// Represents the state of the map, including the controller and zoom level
class MapState {
  /// The MapboxMap controller, used to interact with the map
  final mapbox.MapboxMap? mapController;

  /// Current zoom level of the map view
  final double zoomLevel;

  MapState({
    this.mapController,
    this.zoomLevel = 14.0,
  });

  /// Creates a copy of the current state with optional new values
  MapState copyWith({
    mapbox.MapboxMap? mapController,
    double? zoomLevel,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  String toString() => 'MapState(zoomLevel: \$zoomLevel, hasController: \${mapController != null})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MapState &&
              runtimeType == other.runtimeType &&
              mapController == other.mapController &&
              zoomLevel == other.zoomLevel;

  @override
  int get hashCode => mapController.hashCode ^ zoomLevel.hashCode;
}