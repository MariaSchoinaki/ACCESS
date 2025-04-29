/// Represents a location (feature) from the Mapbox API.
class MapboxFeature {
  /// Unique ID of the feature (usually the Mapbox ID)
  final String id;

  /// Display name of the feature
  final String name;

  /// Latitude coordinate of the feature
  final double latitude;

  /// Longitude coordinate of the feature
  final double longitude;

  /// Full formatted address of the feature
  final String fullAddress;

  /// List of categories describing the point of interest (e.g., 'cafe', 'hospital')
  final List<String> poiCategory;

  /// Raw metadata associated with the feature, converted into a list of strings
  final List<String> metadata;

  /// Indicates whether the feature is wheelchair accessible
  final bool accessibleFriendly;

  /// Constructs a [MapboxFeature] with all required properties
  MapboxFeature({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.poiCategory,
    required this.metadata,
    required this.accessibleFriendly,
  });

  /// Factory constructor to create a [MapboxFeature] from a JSON object
  factory MapboxFeature.fromJson(Map<String, dynamic> json) {
    /// Coordinates come as a list: [longitude, latitude]
    final coords = json['geometry']?['coordinates'] ?? [0.0, 0.0];

    /// Name fallback to "Unnamed Location" if not available
    final name = json['name'] ?? 'Unnamed Location';

    /// Full address of the location, optional
    final fullAddress = json['full_address'] ?? '';

    /// POI category list, e.g. ['school', 'parking']
    final poiCategory = List<String>.from(json['poi_category'] ?? []);

    /// Metadata is either a map or empty
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    /// Checks if metadata explicitly mentions wheelchair accessibility
    final accessible = metadata.containsKey('wheelchair_accessible') && metadata['wheelchair_accessible'] == true;

    return MapboxFeature(
      id: json['mapbox_id'] ?? 'unknown_id',
      name: name,
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
      fullAddress: fullAddress,
      poiCategory: poiCategory,
      metadata: metadata.entries.map((e) => '${e.key}: ${e.value}').toList(),
      accessibleFriendly: accessible,
    );
  }

  /// Converts the [MapboxFeature] instance to a JSON-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'full_address': fullAddress,
      'poi_category': poiCategory,
    };
  }

  /// Returns a string representation of the object for debugging
  @override
  String toString() => 'MapboxFeature(name: $name, lat: $latitude, lng: $longitude)';

  /// Equality operator override for comparing [MapboxFeature] instances
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MapboxFeature &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              latitude == other.latitude &&
              longitude == other.longitude &&
              fullAddress == other.fullAddress &&
              poiCategory == other.poiCategory;

  /// Hashcode override based on all primary fields
  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      fullAddress.hashCode ^
      poiCategory.hashCode;
}
