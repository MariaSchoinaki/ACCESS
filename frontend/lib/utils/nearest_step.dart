import 'dart:math';

import '../models/navigation_step.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

NavigationStep? findNearestStep(Point userLocation, List<NavigationStep> steps) {
  NavigationStep? nearestStep;
  double shortestDistance = double.infinity;

  for (final step in steps) {
    final d = distanceBetweenPoints(userLocation, step.location);
    if (d < shortestDistance) {
      shortestDistance = d;
      nearestStep = step;
    }
  }

  return nearestStep;
}

double distanceBetweenPoints(Point p1, Point p2) {
  final double lat1 = p1.coordinates.lat.toDouble();
  final double lon1 = p1.coordinates.lng.toDouble();
  final double lat2 = p2.coordinates.lat.toDouble();
  final double lon2 = p2.coordinates.lng.toDouble();

  const R = 6371000;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
          cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) => degree * pi / 180;
