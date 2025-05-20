import 'dart:math';
import 'geojson_models.dart';

/// Calculate the distance (in meters) between two geo points (lon, lat) using Haversine formula.
double haversine(List<double> a, List<double> b) {
  const R = 6371000.0; // Earth radius in meters
  final dLat = _deg2rad(b[1] - a[1]);
  final dLon = _deg2rad(b[0] - a[0]);
  final lat1 = _deg2rad(a[1]);
  final lat2 = _deg2rad(b[1]);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * R * atan2(sqrt(h), sqrt(1 - h));
}

double _deg2rad(double deg) => deg * pi / 180;

/// Calculate distance from a point to a segment (A-B) in lat/lng
double pointToSegmentDistance(List<double> p, List<double> a, List<double> b) {
  // Convert to cartesian approximation for short distances
  final x = p[0], y = p[1];
  final x1 = a[0], y1 = a[1];
  final x2 = b[0], y2 = b[1];

  final dx = x2 - x1;
  final dy = y2 - y1;
  if (dx == 0 && dy == 0) {
    // a and b are the same point
    return haversine(p, a);
  }

  // Calculate the projection of p onto the segment a-b
  final t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
  if (t < 0) {
    // Closest to a
    return haversine(p, a);
  } else if (t > 1) {
    // Closest to b
    return haversine(p, b);
  } else {
    // Projection falls on the segment
    final proj = [x1 + t * dx, y1 + t * dy];
    return haversine(p, proj);
  }
}

/// Finds the nearest GeoJsonFeature (pedestrian segment) for a given point [lng, lat].
GeoJsonFeature? findNearestFeature(
    List<double> point, GeoJsonFeatureCollection collection) {
  double? minDist;
  GeoJsonFeature? nearest;
  for (final feature in collection.features) {
    final coords = feature.geometry.coordinates;
    // For LineString or Polygon ring, check each segment
    for (int i = 0; i < coords.length - 1; i++) {
      final d = pointToSegmentDistance(point, coords[i], coords[i + 1]);
      if (minDist == null || d < minDist) {
        minDist = d;
        nearest = feature;
      }
    }
  }
  return nearest;
}

/// Given a route as List<List<double>> (each [lng, lat]),
/// returns the unique list of GeoJsonFeature ids (road segments) traversed in order.
List<String> matchRouteToSegments(
    List<List<double>> route, GeoJsonFeatureCollection collection) {
  final List<String> matchedSegments = [];
  String? lastId;
  for (final point in route) {
    final feature = findNearestFeature(point, collection);
    final id = feature?.properties['id']?.toString() ?? '';
    if (id.isNotEmpty && id != lastId) {
      matchedSegments.add(id);
      lastId = id;
    }
  }
  return matchedSegments;
}
