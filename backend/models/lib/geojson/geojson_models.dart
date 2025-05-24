/// Models for basic GeoJSON structure.
/// This assumes "FeatureCollection" with "features",
/// each feature is a pedestrian street (LineString or Polygon).

class GeoJsonFeatureCollection {
  final List<GeoJsonFeature> features;

  GeoJsonFeatureCollection({required this.features});

  factory GeoJsonFeatureCollection.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeatureCollection(
      features: (json['features'] as List)
          .map((f) => GeoJsonFeature.fromJson(f))
          .toList(),
    );
  }
}

class GeoJsonFeature {
  final Map<String, dynamic> properties;
  final GeoJsonGeometry geometry;

  GeoJsonFeature({required this.properties, required this.geometry});

  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeature(
      properties: json['properties'] ?? {},
      geometry: GeoJsonGeometry.fromJson(json['geometry']),
    );
  }
}

class GeoJsonGeometry {
  final String type;
  final List<List<double>> coordinates; // Only for LineString or Polygon ring

  GeoJsonGeometry({required this.type, required this.coordinates});

  factory GeoJsonGeometry.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'LineString') {
      final coords = (json['coordinates'] as List)
          .map<List<double>>((c) => [c[0].toDouble(), c[1].toDouble()])
          .toList();
      return GeoJsonGeometry(type: type, coordinates: coords);
    } else if (type == 'Polygon') {
      // Use first ring only (most pedestrian areas)
      final coords = (json['coordinates'][0] as List)
          .map<List<double>>((c) => [c[0].toDouble(), c[1].toDouble()])
          .toList();
      return GeoJsonGeometry(type: type, coordinates: coords);
    }
    throw UnimplementedError('Unsupported geometry type: $type');
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

