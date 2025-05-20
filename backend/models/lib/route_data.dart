
import 'point.dart';

class RouteData {
  final DateTime createdAt;
  final String id;
  final double rating;
  final List<Point> routePoints;
  final int pointCount;
  final String? userEmail, userId;

  RouteData({
    required this.id,
    required this.createdAt,
    required this.rating,
    required this.routePoints,
    this.pointCount = 0,
    this.userEmail,
    this.userId,
  });

  factory RouteData.fromFs({
    required String id,
    required Map<String, dynamic> json, required double defaultRefAcc,
  }) {
    final createdAtRaw = json['createdAt'];
    DateTime _created;
    if (createdAtRaw is Map &&
        createdAtRaw['_seconds'] != null &&
        createdAtRaw['_nanoseconds'] != null) {
      _created = DateTime.fromMillisecondsSinceEpoch(
          createdAtRaw['_seconds'] * 1000 +
              (createdAtRaw['_nanoseconds'] ~/ 1000000),
          isUtc: true);
    } else if (createdAtRaw is String) {
      _created = DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc();
    } else {
      _created = DateTime.now().toUtc();
    }

    final rating = (json['rating'] as num?)?.toDouble() ?? 0.5;

    final points = (json['routePoints'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((p) => Point.fromFs(p, defaultRefAcc: 0.5))
        .toList();

    return RouteData(
      id:        id,
      createdAt: _created,
      rating:    rating,
      routePoints: points,
      userEmail: json['userEmail'] as String?,
      userId:    json['userId'] as String?,
    );
  }

  get defaultRefAcc => 0.5;
}