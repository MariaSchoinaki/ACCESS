

import 'package:cloud_firestore/cloud_firestore.dart';
import 'point.dart';

class RouteData {
  final DateTime createdAt;
  final int pointCount;
  final double rating;
  final List<Point> routePoints;
  final String? userEmail;
  final String? userId;

  RouteData({
    required this.createdAt,
    required this.pointCount,
    required this.rating,
    required this.routePoints,
    this.userEmail,
    this.userId,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    DateTime created;
    var createdAtData = json['createdAt'];

    if (createdAtData is Timestamp) { // Άμεσο αντικείμενο Timestamp από Firestore
      created = createdAtData.toDate();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null && createdAtData['_nanoseconds'] != null) {
      created = DateTime.fromMillisecondsSinceEpoch(
          (createdAtData['_seconds'] as int) * 1000 + (createdAtData['_nanoseconds'] as int) ~/ 1000000
      );
    } else if (createdAtData is String) {
      try { created = DateTime.parse(createdAtData); } catch (e) { created = DateTime.now(); }
    } else {
      // print("Προειδοποίηση: Άγνωστη μορφή createdAt για διαδρομή. Χρησιμοποιείται η τρέχουσα ώρα.");
      created = DateTime.now();
    }

    final double routeOverallRatingAsReference = (json['rating'] as num? ?? 0.0).toDouble(); // Default σε 0.0 αν λείπει
    List<Point> parsedRoutePoints = [];
    if (json['routePoints'] is List) {
      for (var pointMapData in (json['routePoints'] as List)) {
        if (pointMapData is Map<String, dynamic>) { // Έλεγχος τύπου
          parsedRoutePoints.add(
              Point.fromMap(
                  pointMapData,
                  determinedReferenceAccessibility: routeOverallRatingAsReference
              )
          );
        }
      }
    }
    return RouteData(
      createdAt: created,
      pointCount: json['pointCount'] as int? ?? 0, // Default σε 0 αν λείπει
      rating: routeOverallRatingAsReference,
      routePoints: parsedRoutePoints,
      userEmail: json['userEmail'] as String?,
      userId: json['userId'] as String?,
    );
  }
}

class RouteSegment {
  final Point startPoint;
  final Point endPoint;
  final double calculatedAccessibilityScore;
  final String colorHex;

  RouteSegment({
    required this.startPoint,
    required this.endPoint,
    required this.calculatedAccessibilityScore,
    required this.colorHex,
  });
}