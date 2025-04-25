class MapboxFeature {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String fullAddress;
  final List<String> poiCategory;

  MapboxFeature({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.poiCategory,
  });

  // Factory constructor για να δημιουργήσουμε το MapboxFeature από το JSON
  factory MapboxFeature.fromJson(Map<String, dynamic> json) {
    // Εξαγωγή συντεταγμένων
    print(json);
    final coords = json['geometry']?['coordinates'] ?? [0.0, 0.0];

    print((coords[1] as num).toDouble());
    // Εξαγωγή άλλων πληροφοριών
    final name = json['name'] ?? 'Unnamed Location';
    print(name);
    final fullAddress = json['full_address'] ?? '';
    final poiCategory = List<String>.from(json['poi_category'] ?? []);

    return MapboxFeature(
      id: json['mapbox_id'] ?? 'unknown_id',
      name: name,
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
      fullAddress: fullAddress,
      poiCategory: poiCategory,
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
