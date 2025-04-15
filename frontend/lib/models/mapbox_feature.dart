/// A model representing a geographic feature returned from Mapbox Geocoding API
class MapboxFeature {
  final String id;           // Unique identifier for the feature
  final String name;         // Display name of the location
  final double latitude;     // Latitude coordinate
  final double longitude;    // Longitude coordinate

  MapboxFeature({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Factory constructor to create a MapboxFeature from a JSON map
  factory MapboxFeature.fromJson(Map<String, dynamic> json) {
    // Type-safe extraction of coordinates
    final List<dynamic> coords = json['geometry']['coordinates'];

    // Return constructed feature with fallback defaults
    return MapboxFeature(
      id: json['id'] ?? 'unknown_id',
      name: json['place_name'] ?? 'Unnamed Location',
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
    );
  }

  /// Converts the feature back to JSON (optional for caching or debugging)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_name': name,
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };
  }

  @override
  String toString() => 'MapboxFeature(name: \$name, lat: \$latitude, lng: \$longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MapboxFeature &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              latitude == other.latitude &&
              longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}