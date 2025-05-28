import 'dart:math';
import 'package:access_models/report.dart';

// Calculates distance (in meters) using the Haversine formula
double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // Earth radius in meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) => degree * pi / 180;

/// Groups reports that are close in space, time, and type
List<List<Report>> clusterReports(List<Report> reports) {
  final List<List<Report>> clusters = [];

  for (var report in reports) {
    bool addedToCluster = false;

    for (var cluster in clusters) {
      for (var existing in cluster) {
        final distance = haversineDistance(
          report.latitude,
          report.longitude,
          existing.latitude,
          existing.longitude,
        );

        final timeDiff = report.timestamp.difference(existing.timestamp).inDays;

        if (distance < 15 && timeDiff.abs() <= 3) {
          cluster.add(report);
          addedToCluster = true;
          break;
        }
      }
      if (addedToCluster) break;
    }

    if (!addedToCluster) {
      clusters.add([report]);
    }
  }

  return clusters;
}
