class MapboxFeature {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  MapboxFeature({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory MapboxFeature.fromJson(Map<String, dynamic> json) {
    final List coords = json['geometry']['coordinates'];
    return MapboxFeature(
      id: json['id'] ?? '',
      name: json['place_name'] ?? '',
      latitude: coords[1] as double,
      longitude: coords[0] as double,
    );
  }
}
