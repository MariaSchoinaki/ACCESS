class MapboxFeature {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String fullAddress;
  final List<String> poiCategory;
  final List<String> metadata;
  final bool accessibleFriendly;

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

  // Factory constructor to create a MapboxFeature from JSON
  factory MapboxFeature.fromJson(Map<String, dynamic> json) {

    ///coords comes in a list
    final coords = json['geometry']?['coordinates'] ?? [0.0, 0.0];
    final name = json['name'] ?? 'Unnamed Location';
    final fullAddress = json['full_address'] ?? '';
    final poiCategory = List<String>.from(json['poi_category'] ?? []);

    ///metadata is either {something} or {}
    final  metadata = json['metadata'] as Map<String, dynamic>? ?? {};
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

  @override
  String toString() => 'MapboxFeature(name: $name, lat: $latitude, lng: $longitude)';

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

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ latitude.hashCode ^ longitude.hashCode ^ fullAddress.hashCode ^ poiCategory.hashCode;
}
