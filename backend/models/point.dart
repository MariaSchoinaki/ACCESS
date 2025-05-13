import 'dart:convert'; // Για jsonDecode

class Point {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;
  final double referenceAccessibility; // Ο 'βαθμός_αναφοράς' για αυτό το σημείο (από το rating της διαδρομής)

  Point({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    required this.referenceAccessibility,
  });

  factory Point.fromFirebase(Map<String, dynamic> map) {
    final fields = map['mapValue']['fields'];
    return Point(
      latitude: _getDouble(fields['latitude']),
      longitude: _getDouble(fields['longitude']),
      altitude: _getDouble(fields['altitude']),
      accuracy: _getDouble(fields['accuracy']),
      speed: _getDouble(fields['speed']),
      timestamp: fields['timestamp']['stringValue'] ?? '',
      referenceAccessibility: _getDouble(fields['referenceAccessibility']),
    );
  }

  static double _getDouble(Map<String, dynamic>? value) {
    if (value == null) return 0.0;
    return value['doubleValue'] is String
        ? double.tryParse(value['doubleValue']) ?? 0.0
        : value['doubleValue']?.toDouble() ?? 0.0;
  }


  /// Factory constructor για δημιουργία από ένα map (δηλαδή ένα αντικείμενο από τη λίστα routePoints).
  /// Το [determinedReferenceAccessibility] παρέχεται από την [RouteData.fromJson]
  /// και είναι το συνολικό 'rating' της διαδρομής.
  factory Point.fromMap(Map<String, dynamic> map, {required double determinedReferenceAccessibility}) {
    DateTime ts;
    if (map['timestamp'] is Map && map['timestamp']['_seconds'] != null && map['timestamp']['_nanoseconds'] != null) {
      ts = DateTime.fromMillisecondsSinceEpoch(
          (map['timestamp']['_seconds'] as int) * 1000 + (map['timestamp']['_nanoseconds'] as int) ~/ 1000000
      );
    } else if (map['timestamp'] is String) {
      try {
        ts = DateTime.parse(map['timestamp']);
      } catch (e) {
        // print("Προειδοποίηση: Μη αναγνωρίσιμη μορφή timestamp '${map['timestamp']}'. Χρησιμοποιείται η τρέχουσα ώρα. Σφάλμα: $e");
        ts = DateTime.now();
      }
    } else if (map['timestamp'] is num) {
      ts = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    } else {
      // print("Προειδοποίηση: Άγνωστη μορφή timestamp. Χρησιμοποιείται η τρέχουσα ώρα.");
      ts = DateTime.now();
    }

    return Point(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      timestamp: ts,
      referenceAccessibility: determinedReferenceAccessibility,
    );
  }
}
